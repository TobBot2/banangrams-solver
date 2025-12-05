open Core

(** Signature for tiles used in boards *)
module type TILE = sig
  type t [@@deriving sexp, compare, equal]
  type value_t [@@deriving sexp, compare, equal]
  
  val create : Tile.Position.t -> value_t -> t
  val position : t -> Tile.Position.t
  val value : t -> value_t
  
  include Comparable.S with type t := t
end

(** Functor to create Board module for any tile type *)
module Make (T : TILE) = struct
  module Tile_type = T
  
  (* Board is a map from Position to Value *)
  type t = T.value_t Map.M(Tile.Position).t [@@deriving sexp, compare]
  
  let empty = Map.empty (module Tile.Position)
  
  let set tile board =
    Map.set board ~key:(T.position tile) ~data:(T.value tile)
  
  let remove pos board =
    Map.remove board pos
  
  let get pos board =
    Map.find board pos
  
  let get_tile pos board =
    Option.map (get pos board) ~f:(fun value -> T.create pos value)
  
  let mem pos board =
    Map.mem board pos
  
  let to_tiles board =
    Map.fold board ~init:[] ~f:(fun ~key:pos ~data:value acc ->
      T.create pos value :: acc)
  
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
          let pos = T.position tile in
          if mem pos board then
            Error (sprintf "Duplicate position: %s" (Tile.Position.to_string pos))
          else
            go rest (set tile board)
    in
    go tiles empty
end