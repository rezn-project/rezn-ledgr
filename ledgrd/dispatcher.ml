let error msg =
  `Assoc [ "status", `String "error"; "message", `String msg ]

let get_field name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let get_string_field name json =
  match get_field name json with
  | Some (`String s) -> Ok s
  | _ -> Error ("Missing or invalid " ^ name)

let dispatch raw_input db =
  let handle_exn exn =
    Printf.eprintf "Handler error: %s\n%!" (Printexc.to_string exn);
    error "Internal error"
  in
  try
    let json = Yojson.Safe.from_string raw_input in
    match get_field "op" json with
    | Some (`String "list") ->
        let entries = Dao.list_entries db in
        let json_entries = `List (List.map Types.entry_to_yojson entries) in
        `Assoc [ "status", `String "ok"; "entries", json_entries ]

    | Some (`String "get") ->
        (match get_string_field "id" json with
         | Ok id ->
             (match Dao.get_entry db id with
              | Some entry -> `Assoc [ "status", `String "ok"; "entry", Types.entry_to_yojson entry ]
              | None -> error "Not found")
         | Error msg -> error msg)

    | Some (`String "create") ->
        (match get_field "entry" json with
         | Some entry_json ->
             (match Types.entry_of_yojson entry_json with
              | Ok entry ->
                  (match Dao.create_entry db entry with
                   | Ok () -> `Assoc [ "status", `String "ok" ]
                   | Error msg -> error msg)
              | Error msg -> error ("Invalid entry: " ^ msg))
         | None -> error "Missing entry")

    | Some (`String "delete") ->
        (match get_string_field "id" json with
         | Ok id ->
             (match Dao.delete_entry db id with
              | Ok () -> `Assoc [ "status", `String "ok" ]
              | Error msg -> error msg)
         | Error msg -> error msg)

    | Some (`String unknown_op) ->
        error ("Unknown op: " ^ unknown_op)

    | _ ->
        error "Missing op field"
  with exn -> handle_exn exn