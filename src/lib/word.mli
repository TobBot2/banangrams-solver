open Core

module Word : sig

  type t = Tile.t list [@@deriving sexp, compare, equal]

  val create : Tile.Position.t  -> Tile.Value.t list -> t
  (** Create a word *)

  val start : t -> Tile.Position.t
  (** Starting position of the word *)

  val chars : t -> char list
  (** Characters in the word *)

  val to_string : t -> string
  (** Convert word to string (e.g., "HELLO") *)

  val length : t -> int
  (** Number of characters in word *)

  val of_tiles : t -> int
  (** Need to implemenet for Validation *)
end