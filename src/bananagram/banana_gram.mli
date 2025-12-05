open Core

(** Banana_gram module: Instantiates all generic library modules with char type
    
    This module provides the concrete types and functions for BananaGrams 
    by instantiating the generic library with characters.
*)

(** CharValue module for character tiles *)
module CharValue : sig
  type t = char [@@deriving sexp, compare, equal]
  val to_string : t -> string
  include Comparable.S with type t := t
end

(** Tile module - tiles containing characters *)
module Tile : sig
  type t [@@deriving sexp, compare, equal]
  type value_t = CharValue.t [@@deriving sexp, compare, equal]
  
  module Value : sig
    type t = CharValue.t [@@deriving sexp, compare, equal]
    val to_string : t -> string
    include Comparable.S with type t := t
  end
  
  val create : Lib.Tile.Position.t -> CharValue.t -> t
  val position : t -> Lib.Tile.Position.t
  val value : t -> CharValue.t
  val to_string : t -> string
  
  include Comparable.S with type t := t
end

(** Word module - words as lists of character tiles *)
module Word : sig
  type t = Tile.t list [@@deriving sexp, compare, equal]
  
  val create : Lib.Tile.Position.t -> char list -> t
  val start : t -> Lib.Tile.Position.t
  val values : t -> char list
  val to_string : t -> string
  val length : t -> int
  val is_empty : t -> bool
  val tiles : t -> Tile.t list
  
  include Comparable.S with type t := t
end

(** Board module - map from positions to characters *)
module Board : sig
  type t = char Map.M(Lib.Tile.Position).t [@@deriving sexp, compare]
  
  val empty : t
  val set : Tile.t -> t -> t
  val remove : Lib.Tile.Position.t -> t -> t
  val get : Lib.Tile.Position.t -> t -> char option
  val get_tile : Lib.Tile.Position.t -> t -> Tile.t option
  val mem : Lib.Tile.Position.t -> t -> bool
  val to_tiles : t -> Tile.t list
  val positions : t -> Lib.Tile.Position.t list
  val is_empty : t -> bool
  val size : t -> int
  val of_tiles : Tile.t list -> (t, string) Result.t
end

(** Convenient type aliases *)

type tile = Tile.t
(** A tile containing a character at a position *)

type word = Word.t
(** A word is a list of tiles *)

type board = Board.t
(** A board is a map from positions to character values *)

type position = Lib.Tile.Position.t
(** A position on the board (row, col) *)

(** Helper functions *)

val create_tile : position -> char -> tile
(** [create_tile pos letter] creates a tile with the given letter at position *)

val create_word : position -> char list -> word
(** [create_word start letters] creates a word starting at position with the given letters *)

val empty_board : unit -> board
(** [empty_board ()] creates an empty board *)

val place_word_on_board : word -> board -> board
(** [place_word_on_board word board] places all tiles from word onto board *)

val get_letter_at : position -> board -> char option
(** [get_letter_at pos board] returns the letter at position, if any *)

val word_to_string : word -> string
(** [word_to_string word] converts word to string representation *)