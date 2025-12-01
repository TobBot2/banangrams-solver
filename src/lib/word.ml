open Core

type t = Tile.t list [@@deriving sexp, compare, equal]

let create start values =
  List.mapi values ~f:(fun i v ->
    let pos = Tile.Position.create 
      (Tile.Position.row start) 
      (Tile.Position.col start + i) in
    Tile.create pos v)

  (** Increments the position horizontally - not sure if this is the best approach?*)

let start word =
  match word with
  | [] -> failwith "Word.start: empty word"
  | tile :: _ -> Tile.position tile

let chars word =
  List.map word ~f:(fun tile -> 
    Tile.Value.to_char (Tile.value tile))

let to_string word =
  chars word
  |> List.map ~f:Char.to_string
  |> String.concat ~sep:""

let length word =
  List.length word