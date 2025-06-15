(* filepath: /home/andrea/dev/rezn-ledgr/ledgrd/dispatcher.ml *)
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

    | `Assoc [ ("op", `String "get"); ("id", `String id) ] ->
        (match Dao.get_entry db id with
         | Some entry ->
             `Assoc [
               "status", `String "ok";
               "entry", Types.entry_to_yojson entry
             ]
         | None ->
             `Assoc [
               "status", `String "error";
               "message", `String "Not found"
             ])

    | `Assoc [ ("op", `String "create"); ("entry", entry_json) ] ->
        (match Types.entry_of_yojson entry_json with
         | Ok entry ->
             (match Dao.create_entry db entry with
              | Ok () ->
                  `Assoc [
                    "status", `String "ok"
                  ]
              | Error msg ->
                  `Assoc [
                    "status", `String "error";
                    "message", `String msg
                  ])
         | Error msg ->
             `Assoc [
               "status", `String "error";
               "message", `String ("Invalid entry: " ^ msg)
             ])

    | `Assoc [ ("op", `String "delete"); ("id", `String id) ] ->
        (match Dao.delete_entry db id with
         | Ok () ->
             `Assoc [
               "status", `String "ok"
             ]
         | Error msg ->
             `Assoc [
               "status", `String "error";
               "message", `String msg
             ])

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