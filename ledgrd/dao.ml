open Types

let create_entry db (e : entry) : (unit, string) result =
  let sql = "INSERT INTO entries (id, name, host) VALUES (?, ?, ?)" in
  let stmt = Sqlite3.prepare db sql in
  match
    Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT e.id),
    Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT e.name),
    Sqlite3.bind stmt 3 (Sqlite3.Data.TEXT e.host),
    Sqlite3.step stmt
  with
  | Sqlite3.Rc.OK, _, _, Sqlite3.Rc.DONE ->
      ignore (Sqlite3.finalize stmt);
      Ok ()
  | _, _, _, rc ->
      ignore (Sqlite3.finalize stmt);
      Error (Sqlite3.Rc.to_string rc)

let get_entry db id : entry option =
  let sql = "SELECT id, name, host FROM entries WHERE id = ?" in
  let stmt = Sqlite3.prepare db sql in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT id));
  let rc = Sqlite3.step stmt in
  let result =
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
  in
  ignore (Sqlite3.finalize stmt);
  result

let list_entries db : entry list =
  let sql = "SELECT id, name, host FROM entries ORDER BY name ASC" in
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
    | _ -> loop acc
  in
  let result = loop [] in
  ignore (Sqlite3.finalize stmt);
  result

let delete_entry db id : (unit, string) result =
  let sql = "DELETE FROM entries WHERE id = ?" in
  let stmt = Sqlite3.prepare db sql in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT id));
  match Sqlite3.step stmt with
  | Sqlite3.Rc.DONE ->
      ignore (Sqlite3.finalize stmt);
      Ok ()
  | rc ->
      ignore (Sqlite3.finalize stmt);
      Error (Sqlite3.Rc.to_string rc)
