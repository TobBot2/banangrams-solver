open Core

(** Tile module representing a character placed at a position on the board *)

module Position : sig
  type t = int * int [@@deriving sexp, compare, equal]
  
  val create : int -> int -> t
  (** [create row col] creates a position *)
  
  val row : t -> int
  val col : t -> int
  
  val up : t -> t
  (** Move one position up (row - 1) *)
  
  val down : t -> t
  (** Move one position down (row + 1) *)
  
  val right : t -> t
  (** Move one position right (col + 1) *)
  
  val left : t -> t
  (** Move one position left (col - 1) *)
  
  val neighbor : Direction.t -> t -> t
  (** Get neighbor position in given direction *)
  
  val to_string : t -> string
  val of_string : string -> t
  
  include Comparable.S with type t := t
end

module Value : sig
  type t = char [@@deriving sexp, compare, equal]
  
  val of_char : char -> t
  val to_char : t -> char
  val to_string : t -> string
  
  include Comparable.S with type t := t
end

(** A tile is a character value at a position *)
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
(** String representation: "C@(0,0)" *)

val map_value : (Value.t -> Value.t) -> t -> t
(** Transform the value while keeping position *)

val move_to : Position.t -> t -> t
(** Move tile to a new position *)

val move : Direction.t -> t -> t
(** Move tile one step in given direction *)

include Comparable.S with type t := t
include Sexpable.S with type t := t