open Types

let log_query sql bindings =
  let params =
    bindings
    |> List.map (fun (idx, data) ->
         Printf.sprintf "$%d=%s" idx
           (match data with
            | Sqlite3.Data.NONE -> "<unbound>"
            | Sqlite3.Data.NULL -> "NULL"
            | Sqlite3.Data.INT i -> Int64.to_string i
            | Sqlite3.Data.FLOAT f -> string_of_float f
            | Sqlite3.Data.TEXT s -> Printf.sprintf "\"%s\"" s
            | Sqlite3.Data.BLOB _ -> "<blob>"))
    |> String.concat ", "
  in
  Printf.eprintf "[SQL] %s [%s]\n%!" sql params

let with_stmt db sql f =
  let stmt = Sqlite3.prepare db sql in
  let res =
    try f stmt
    with exn ->
      ignore (Sqlite3.finalize stmt);
      raise exn
  in
  ignore (Sqlite3.finalize stmt);
  res
  
let finalize_and_error stmt rc =
  ignore (Sqlite3.finalize stmt);
  Error (Sqlite3.Rc.to_string rc)

let rec bind_all stmt = function
  | [] -> Ok ()
  | (idx, data) :: rest ->
      match Sqlite3.bind stmt idx data with
      | Sqlite3.Rc.OK -> bind_all stmt rest
      | rc -> Error rc

let exec_nonquery db sql bindings =
  log_query sql bindings;
  with_stmt db sql (fun stmt ->
    match bind_all stmt bindings with
    | Ok () ->
        (match Sqlite3.step stmt with
         | Sqlite3.Rc.DONE -> Ok ()
         | rc -> 
            Printf.eprintf "[SQL ERROR] %s\n%!" (Sqlite3.Rc.to_string rc);
            Error (Sqlite3.Rc.to_string rc))
    | Error rc -> 
      Printf.eprintf "[BIND ERROR] %s\n%!" (Sqlite3.Rc.to_string rc);
      Error (Sqlite3.Rc.to_string rc)
  )

let create_entry db (e : entry) =
  exec_nonquery db
    "INSERT INTO entries (id, name, host) VALUES (?, ?, ?)"
    [ (1, Sqlite3.Data.TEXT e.id);
      (2, Sqlite3.Data.TEXT e.name);
      (3, Sqlite3.Data.TEXT e.host) ]

let get_entry db id : entry option =
  let sql = "SELECT id, name, host FROM entries WHERE id = ?" in
  log_query sql [ (1, Sqlite3.Data.TEXT id) ];
  with_stmt db sql (fun stmt ->
    match bind_all stmt [ (1, Sqlite3.Data.TEXT id) ] with
    | Ok () ->
        let rc = Sqlite3.step stmt in
        if rc = Sqlite3.Rc.ROW then
          match
            Sqlite3.column stmt 0,
            Sqlite3.column stmt 1,
            Sqlite3.column stmt 2
          with
          | Sqlite3.Data.TEXT id,
            Sqlite3.Data.TEXT name,
            Sqlite3.Data.TEXT host -> Some { id; name; host }
          | _ -> None
        else
          None
    | Error _ -> None
  )

let list_entries db : entry list =
  let sql = "SELECT id, name, host FROM entries ORDER BY name ASC" in
  log_query sql [];
  let stmt = Sqlite3.prepare db sql in
  let rec loop acc =
    match Sqlite3.step stmt with
    | rc when rc = Sqlite3.Rc.ROW ->
        (match
           Sqlite3.column stmt 0,
           Sqlite3.column stmt 1,
           Sqlite3.column stmt 2
         with
         | Sqlite3.Data.TEXT id,
           Sqlite3.Data.TEXT name,
           Sqlite3.Data.TEXT host ->
             loop ({ id; name; host } :: acc)
         | _ -> loop acc)
    | Sqlite3.Rc.DONE -> List.rev acc
    | rc -> failwith ("SQLite error: " ^ Sqlite3.Rc.to_string rc)
  in
  let result = loop [] in
  ignore (Sqlite3.finalize stmt);
  result

let delete_entry db id =
  exec_nonquery db
    "DELETE FROM entries WHERE id = ?"
    [ (1, Sqlite3.Data.TEXT id) ]
