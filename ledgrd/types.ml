type migration = {
  version : int;
  sql : string;
}

type entry = {
  id: string;
  name: string;
  host: string;
} [@@deriving yojson]

