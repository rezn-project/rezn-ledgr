open Lwt.Syntax

(* ---------- configuration helpers ---------- *)

let default_socket_path   = "/run/reznledgr/rezn.sock"
let fallback_socket_path  = "/tmp/reznledgr.sock"

let get_db_path () =
  match Sys.getenv_opt "LEDGR_DB_PATH" with
  | Some p -> p
  | None   -> "ledger.db"

let get_socket_path () =
  match Sys.getenv_opt "SOCKET_PATH" with
  | Some p -> p
  | None   ->
    if Sys.file_exists "/run/reznledgr" then
      try
        let test_file =
          Filename.concat "/run/reznledgr" ".rezn_write_test" in
        let oc = open_out_gen [Open_creat; Open_wronly] 0o600 test_file in
        close_out oc; Sys.remove test_file; default_socket_path
      with _ -> fallback_socket_path
    else
      fallback_socket_path

let socket_path = get_socket_path ()

(* Ensure directory exists (Dream will create the socket file) *)
let () =
  let dir = Filename.dirname socket_path in
  try Unix.mkdir dir 0o770 with Unix.Unix_error (Unix.EEXIST,_,_) -> ()

(* ---------- one-off start-up migration ---------- *)

let () =
  (* Runs before Dream’s event loop starts, so blocking here is fine. *)
  let db = Sqlite3.db_open (get_db_path ()) in
  Migrations.migrate db;
  ignore (Sqlite3.db_close db)

(* ---------- request handler ---------- *)

let handle_raw raw =
  (* move heavy Sqlite work off the main event loop *)
  Lwt_preemptive.detach
    (fun () ->
       let db = Sqlite3.db_open (get_db_path ()) in
       let result =
         try Dispatcher.dispatch raw db with exn ->
           Printf.eprintf "Handler error: %s\n%!"
             (Printexc.to_string exn);
           `Assoc [
             "status",  `String "error";
             "message", `String "Internal error"]
       in
       ignore (Sqlite3.db_close db);
       result)
    ()

let dream_handler req =
  let* body   = Dream.body req in
  let* json   = handle_raw body in
  Dream.json (Yojson.Safe.to_string json)

(* ---------- graceful shutdown plumbing ---------- *)

let stop_promise, stop_wakener = Lwt.wait ()

let () =
  let stop () = Lwt.wakeup_later stop_wakener () in
  Sys.set_signal Sys.sigterm (Sys.Signal_handle (fun _ -> stop ()));
  Sys.set_signal Sys.sigint  (Sys.Signal_handle (fun _ -> stop ()));
  at_exit (fun () ->
      if Sys.file_exists socket_path then Sys.remove socket_path)

(* ---------- run Dream ---------- *)

let () =
  Dream.run
    ~socket_path          (* Unix-domain socket instead of TCP, keeps old IPC path *)
    ~greeting:false       (* silence the “Dream is serving …” line *)
    ~stop:stop_promise    (* tie in the SIGTERM/SIGINT logic *)
  @@ Dream.logger         (* same nice request log you had with Printf *)
  @@ Dream.router [
       Dream.post "/" dream_handler;  (* single JSON endpoint *)
     ]
