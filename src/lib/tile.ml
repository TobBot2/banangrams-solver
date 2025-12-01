open Core

module type VALUE = sig
  type t [@@deriving sexp, compare, equal]
  val to_string : t -> string
end

(* Char instantiation - HIDDEN, only used internally *)
module Char_value = struct
  type t = char [@@deriving sexp, compare, equal]
    let to_string c = String.make 1 c
end

(** module Char_tile = Tile.Make(Char_value) **)
module Position = struct
  type t = int * int [@@deriving sexp, compare, equal]
  
  let create row col = (row, col)
  
  let row (r, _) = r
  let col (_, c) = c
  
  let up (row, col) = (row - 1, col)
  let down (row, col) = (row + 1, col)
  let right (row, col) = (row, col + 1)
  let left (row, col) = (row, col - 1)
  
  let to_string (row, col) = sprintf "(%d,%d)" row col
  
end

module Make (V : VALUE) = struct
  module Value = V
  
  type t = {
    position : Position.t;
    value : Value.t;
  } [@@deriving sexp, compare, equal]
  
  let create position value = { position; value }
  
  let position tile = tile.position
  
  let value tile = tile.value
  
  let to_string tile =
    sprintf "%s@%s" 
      (Value.to_string tile.value)
      (Position.to_string tile.position)
end



