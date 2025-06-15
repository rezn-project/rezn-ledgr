open Types

let migrations : migration list = [
  {
    version = 1;
    sql = {|
      CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL
      );
    |}
  };
]

let get_version db : int option =
  let stmt = Sqlite3.prepare db "PRAGMA user_version;" in
  match Sqlite3.step stmt with
  | rc when rc = Sqlite3.Rc.ROW ->
      let v = Sqlite3.column stmt 0 in
      ignore (Sqlite3.finalize stmt);
      begin match v with
      | Sqlite3.Data.INT i -> Some (Int64.to_int i)
      | _ -> None
      end
  | _ ->
      ignore (Sqlite3.finalize stmt);
      None


let set_version db v =
  ignore (Sqlite3.exec db (Printf.sprintf "PRAGMA user_version = %d;" v))

let migrate db : unit =
  match get_version db with
  | None ->
      failwith "❌ Failed to read database version"

  | Some current_version ->
      let pending =
        List.filter (fun m -> m.version > current_version) migrations
        |> List.sort (fun a b -> compare a.version b.version)
      in

      List.iter (fun m ->
        Printf.printf "🚧 Applying migration %d...\n%!" m.version;
        match Sqlite3.exec db m.sql with
        | Sqlite3.Rc.OK ->
            set_version db m.version
        | rc ->
            failwith (Printf.sprintf "Migration %d failed: %s" m.version (Sqlite3.Rc.to_string rc))
      ) pending


  