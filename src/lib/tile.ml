open Core

(** Signature for tile values *)
module type VALUE = sig
  type t [@@deriving sexp, compare, equal]
  
  val to_string : t -> string 

  include Comparable.S with type t := t
end

(** Position module *)
module Position = struct
  module T = struct
    type t = int * int [@@deriving sexp, compare, equal]
  end
  include T
  include Comparable.Make(T)
  
  let create row col = (row, col)
  
  let row (r, _) = r
  let col (_, c) = c
  
  let left (row, col) = (row - 1, col)
  let right (row, col) = (row + 1, col)
  let up (row, col) = (row, col + 1)
  let down (row, col) = (row, col - 1)
  
  let to_string (r, c) = Printf.sprintf "(%d,%d)" r c
end

(** Functor to create Tile module for any value type *)
module Make (V : VALUE) = struct
  module Value = V
  
  module T = struct
    type t = {
      position : Position.t;
      value : Value.t;
    } [@@deriving sexp, compare, equal]
  end
  include T
  include Comparable.Make(T)
  
  let create position value = { position; value }
  
  let position t = t.position
  
  let value t = t.value
  
  let to_string t = 
    Printf.sprintf "%s@%s" 
      (Value.to_string t.value)
      (Position.to_string t.position)
end