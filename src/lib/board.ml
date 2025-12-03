open Core

(* Board is a map from Position to Value *)
type t = Tile.Value.t Map.M(Tile.Position).t [@@deriving sexp, compare]

let empty = Map.empty (module Tile.Position)

let set tile board =
  Map.set board ~key:(Tile.position tile) ~data:(Tile.value tile)

let remove pos board =
  Map.remove board pos

let get pos board =
  Map.find board pos

let get_tile pos board =
  Option.map (get pos board) ~f:(fun value -> Tile.create pos value)

let mem pos board =
  Map.mem board pos

let to_tiles board =
  Map.fold board ~init:[] ~f:(fun ~key:pos ~data:value acc ->
    Tile.create pos value :: acc)

let positions board =
  Map.keys board

let is_empty board =
  Map.is_empty board

let size board =
  Map.length board

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