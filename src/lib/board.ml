open Core

(* Create a Position map module *)
module Position_map = Map.Make(struct
  type t = Tile.Position.t [@@deriving sexp, compare]
end)

(* Board is a map from Position to Value *)
type t = Tile.Value.t Position_map.t [@@deriving sexp, compare]

let empty = Position_map.empty

let set tile board =
  Position_map.set board ~key:(Tile.position tile) ~data:(Tile.value tile)

let remove pos board =
  Position_map.remove board pos

let get pos board =
  Position_map.find board pos

let get_tile pos board =
  Option.map (get pos board) ~f:(fun value -> Tile.create pos value)

let mem pos board =
  Position_map.mem board pos

let to_tiles board =
  Position_map.fold board ~init:[] ~f:(fun ~key:pos ~data:value acc ->
    Tile.create pos value :: acc)

let positions board =
  Position_map.keys board

let is_empty board =
  Position_map.is_empty board

let size board =
  Position_map.length board

let of_tiles tiles =
  let rec go remaining board =
    match remaining with
    | [] -> Ok board
    | tile :: rest ->
        let pos = Tile.position tile in
        if mem pos board then
          Error (sprintf "Duplicate position: %s" (Tile.Position.to_string pos))
        else
          go rest (set tile board)
  in
  go tiles empty