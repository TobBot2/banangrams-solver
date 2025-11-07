open Core

(** Board validation: word extraction, connectivity, and dictionary checking *)

(** Dictionary interface for word validation *)
module type DICTIONARY = sig
  type t
  
  val contains : t -> string -> bool
  (** Check if word is in dictionary *)
end

val is_word_start : Tile.Position.t -> Direction.t -> Board.t -> bool
(** [is_word_start pos dir board] returns true if [pos] starts a word in [dir].
    
    For Horizontal:
    - Tile exists at pos
    - No tile to the left
    - Tile exists to the right
    
    For Vertical:
    - Tile exists at pos  
    - No tile to up
    - Tile exists to down *)

val extract_word_at : Tile.Position.t -> Direction.t -> Board.t -> Word.t option
(** [extract_word_at pos dir board] extracts the word starting at [pos] in [dir].
    Returns None if [pos] doesn't start a word in that direction. *)

val extract_all_words : Board.t -> Word.t list
(** Extract all words (horizontal and vertical) from the board.
    Only returns words of length >= 2. *)

val words_at_position : Tile.Position.t -> Board.t -> Word.t list
(** Get all words that pass through a given position.
    Used to check what words would be affected by placing/removing a tile. *)

val is_connected : Board.t -> bool
(** Check if all tiles form one connected component.
    Uses DFS from arbitrary starting tile.
    Empty board returns true. *)

val connected_component : Tile.Position.t -> Board.t -> Tile.Position.t list
(** Get all positions connected to the given position.
    Returns empty list if position is not on board. *)

module Make (Dict : DICTIONARY) : sig
  val validate : Board.t -> Dict.t -> (unit, string list) result
  (** [validate board dict] checks if board is valid:
      1. All tiles are connected
      2. All words (length >= 2) are in dictionary
      
      Returns:
      - Ok () if valid
      - Error invalid_words if validation fails *)
  
  val find_invalid_words : Board.t -> Dict.t -> string list
  (** Returns list of words on board not in dictionary *)
  
  val would_be_valid : Tile.t list -> Board.t -> Dict.t -> (unit, string list) result
  (** Check if placing tiles would result in a valid board.
      Useful for validating moves before applying them. *)
end