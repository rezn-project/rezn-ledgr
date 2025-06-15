let dispatch raw_input db =
  try
    match Yojson.Safe.from_string raw_input with
    | `Assoc [ ("op", `String "list") ] ->
        let entries = Dao.list_entries db in
        let json_entries = `List (List.map Types.entry_to_yojson entries) in
        `Assoc [
          "status", `String "ok";
          "entries", json_entries
        ]

    | `Assoc [ ("op", `String unknown_op) ] ->
        `Assoc [
          "status", `String "error";
          "message", `String ("Unknown op: " ^ unknown_op)
        ]

    | _ ->
        `Assoc [
          "status", `String "error";
          "message", `String "Invalid request format"
        ]
  with exn ->
    Printf.eprintf "Handler error: %s\n%!" (Printexc.to_string exn);
    `Assoc [
      "status", `String "error";
      "message", `String "Internal error"
    ]