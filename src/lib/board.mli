open Core

(** Immutable board representation using a map from positions to characters *)

type t [@@deriving sexp, compare]
(** The board type - a map from Position to char values *)

val empty : t
(** Create an empty board *)

val set : Tile.Position.t -> char -> t -> t
(** [set pos value board] returns a NEW board with [value] at [pos].
    Overwrites if position already occupied. *)

val remove : Tile.Position.t -> t -> t
(** [remove pos board] returns a NEW board with position [pos] cleared.
    No-op if position was already empty. *)

val get : Tile.Position.t -> t -> char option
(** [get pos board] returns [Some value] if position has a tile, [None] otherwise *)

val mem : Tile.Position.t -> t -> bool
(** [mem pos board] returns true if position has a tile *)


val get_up : Tile.Position.t -> t -> char option
(** Get character at position above *)

val get_down : Tile.Position.t -> t -> char option
(** Get character at position below *)

val get_right : Tile.Position.t -> t -> char option
(** Get character at position to the right *)

val get_left : Tile.Position.t -> t -> char option
(** Get character at position to the left *)

val get_neighbor : Tile.Position.t -> Direction.t -> t -> char option
(** Get character in given direction from position *)

val neighbors : Tile.Position.t -> t -> (Direction.t * char) list
(** Get all adjacent characters (up to 4) with their directions *)

val has_neighbor : Tile.Position.t -> t -> bool
(** Check if position has at least one adjacent tile *)

val get_tile : Tile.Position.t -> t -> Tile.t option
(** Get tile at position (reconstructs Tile from position + char) *)

val to_tiles : t -> Tile.t list
(** Convert all positions and values to Tile list *)

val place_tiles : Tile.t list -> t -> t
(** Place multiple tiles on board *)

val to_alist : t -> (Tile.Position.t * char) list
(** Get all tiles as association list *)

val of_alist_exn : (Tile.Position.t * char) list -> t
(** Create board from association list. Raises if duplicate positions. *)

val is_empty : t -> bool
(** Check if board has no tiles *)

val size : t -> int
(** Count of tiles on board *)

val fold : t -> init:'acc -> f:(key:Tile.Position.t -> data:char -> 'acc -> 'acc) -> 'acc
(** Fold over all tiles on the board *)

val iter : t -> f:(key:Tile.Position.t -> data:char -> unit) -> unit
(** Iterate over all tiles on the board *)

val bounds : t -> (Tile.Position.t * Tile.Position.t) option
(** Get bounding box as (min_position, max_position).
    Returns None for empty board. *)

val to_string : t -> string
(** ASCII representation of the board *)

include Sexpable.S with type t := t