open Core

(** Represents a word found on the board *)

type t = {
  start : Tile.Position.t;
  direction : Direction.t;
  chars : char list;
} [@@deriving sexp, compare, equal]

val create : Tile.Position.t -> Direction.t -> char list -> t
(** Create a word *)

val start : t -> Tile.Position.t
(** Starting position of the word *)

val direction : t -> Direction.t
(** Direction of the word *)

val chars : t -> char list
(** Characters in the word *)

val to_string : t -> string
(** Convert word to string (e.g., "HELLO") *)

val length : t -> int
(** Number of characters in word *)

val positions : t -> Tile.Position.t list
(** All positions on the board used up by this word *)

val contains_position : Tile.Position.t -> t -> bool
(** Check if word is within given position *)

include Comparable.S with type t := t
include Sexpable.S with type t := t