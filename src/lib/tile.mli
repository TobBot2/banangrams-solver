open Core

(** Tile module representing a character placed at a position on the board *)

module Position : sig
  type t = int * int [@@deriving sexp, compare, equal]
  
  val to_string : t -> string
  val of_string : string -> t
end

module Value : sig
  type t = char [@@deriving sexp, compare, equal]
  
  val to_string : t -> string
  val of_char : char -> t
  val to_char : t -> char
end

type t = {
  position : Position.t;
  value : Value.t;
} [@@deriving sexp, compare, equal]

val create : Position.t -> char -> t
(** Create a tile with a position and character value *)

val position : t -> Position.t
(** Get the position of the tile *)

val value : t -> Value.t
(** Get the character value of the tile *)

val to_string : t -> string
(** String representation: "Char@(row,col)" *)

val map_value : (Value.t -> Value.t) -> t -> t
(** Transform the value while keeping position *)

val move_to : Position.t -> t -> t
(** Move tile to a new position *)