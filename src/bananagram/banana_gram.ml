open Core

(** Banana_gram module: Instantiates all generic library modules with char type
    
    This module is the bridge between the generic library (lib)
    and the specific BananaGrams application.
*)

(**  Define CharValue - the value type for BananaGram tiles *)
module CharValue = struct
  module T = struct
    type t = char [@@deriving sexp, compare, equal]
  end
  include T
  include Comparable.Make(T)
  
  let to_string c = String.make 1 c
end

(** Create CharTile by instantiating Tile functor with CharValue *)
module Tile = struct
  include Lib.Tile.Make(CharValue)
  
  (* Expose value_t at the top level for Word.TILE signature *)
  type value_t = CharValue.t [@@deriving sexp, compare, equal]
  
  (* Expose Value module for Word.TILE signature *)
  module Value = CharValue
end

(*** Create CharWord by instantiating Word functor with CharTile *)
module Word = Lib.Word.Make(Tile)

(** Create CharBoard by instantiating Board functor with CharTile *)
module Board = Lib.Board.Make(Tile)

(** Convenient type aliases *)
type tile = Tile.t
(** A tile containing a character at a position *)

type word = Word.t
(** A word is a list of tiles *)

type board = Board.t
(** A board is a map from positions to character values *)

type position = Lib.Tile.Position.t
(** A position on the board (row, col) *)

(** Helper functions that work with the instantiated types *)

let create_tile (pos : position) (letter : char) : tile =
  Tile.create pos letter

let create_word (start : position) (letters : char list) : word =
  Word.create start letters

let empty_board () : board =
  Board.empty

let place_word_on_board (word : word) (board : board) : board =
  List.fold (Word.tiles word) ~init:board ~f:(fun b tile ->
    Board.set tile b
  )

let get_letter_at (pos : position) (board : board) : char option =
  Board.get pos board

let word_to_string (word : word) : string =
  Word.to_string word