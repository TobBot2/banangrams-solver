open Core

(** Board validation: word extraction, connectivity, and dictionary checking *)

(** Dictionary interface for word validation *)
module type DICTIONARY = sig
  type t
  (** Dictionary type for word validation *)
  
  val load : string -> (t, string) result
  (** [load filepath] loads a dictionary from a file.
      File should contain one word per line. *)
  
  val contains : t -> string -> bool
  (** [contains dict word] checks if [word] exists in the dictionary.
      Case-insensitive. *)
end
(** Loop through the board (ie a map) to find the start of the word, figuring out whether its vertial or horizontal then store that(?) for further validation steps *)
(** Validate that all tiles given to a player were used in the board object returned from the server*)
module Dictionary : DICTIONARY

val is_word_start_horizontal : Tile.Position.t -> Board.t -> bool
(** [is_word_start_horizontal pos board] returns true if [pos] starts a horizontal word.
    
    A position is a horizontal word start if:
    - A tile exists at [pos]
    - No tile exists to the left
    - A tile exists to the right
*)

val is_word_start_vertical_down : Tile.Position.t -> Board.t -> bool
(** [is_word_start_vertical_down pos board] returns true if [pos] starts a vertical word going downward.
    
    A position is a vertical word start (downward) if:
    - A tile exists at [pos]
    - No tile exists to the above
    - A tile exists to the below
*)

val extract_word_horizontal : Tile.Position.t -> Board.t -> Word.t option
(** [extract_word_horizontal pos board] extracts the horizontal word starting at [pos].
    
    Returns [None] if [pos] is not a horizontal word start.
    Follows tiles to the right until no more tiles exist.
*)

val extract_word_vertical_down : Tile.Position.t -> Board.t -> Word.t option
(** [extract_word_vertical_down pos board] extracts the vertical word going downward starting at [pos].
    
    Returns [None] if [pos] is not a vertical word start going down.
    Follows tiles to the down until no more tiles exist.
*)


val extract_all_words : Board.t -> Word.t list
(** [extract_all_words board] finds all words on the board.
    
    - Checks every position for horizontal and vertical word starts 
    - Only returns words of length >= 2
    - Single isolated letters are not considered words
*)

val is_connected : Board.t -> bool
(** [is_connected board] checks if all tiles form one connected component.
    
    Uses depth-first search starting from an arbitrary tile.
    Returns [true] for empty boards.
    
    Connected means each tile has at least one adjacent tile (horizontal or vertical),
    forming a single continuous group.
*)

val connected_positions : Tile.Position.t -> Board.t -> Tile.Position.Set.t
(** [connected_positions start board] returns all positions reachable from [start]
    via adjacent tiles (up/down/left/right).
    
    Helper function that performs DFS from a starting position.
*)

val validate : Board.t -> Dictionary.t -> (unit, string list) result
(** [validate board dict] validates the entire board.
    
    Checks:
    1. All tiles are connected (single component)
    2. All words (length >= 2) exist in dictionary
    
    Returns:
    - [Ok ()] if board is valid
    - [Error invalid_words] where [invalid_words] is a list of words not in dictionary
    
    Note: Returns [Ok ()] for empty boards.
*)

val find_invalid_words : Board.t -> Dictionary.t -> string list
(** [find_invalid_words board dict] returns list of words on board not in dictionary.
    
    Does not check connectivity - only word validity.
    Useful for debugging which specific words are problematic.
*)

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
end