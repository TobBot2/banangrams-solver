open Core

(** Immutable board representation using a map from positions to tile values *)

type t [@@deriving sexp, compare]
(** The board type - a map from Position to Value *)

val empty : t
(** Create an empty board *)

(** {2 Basic Operations} *)

val set : Tile.t -> t -> t
(** [set tile board] returns a NEW board with [tile] placed at its position.
    Overwrites if position already occupied. *)

val set_at : Tile.Position.t -> Tile.Value.t -> t -> t
(** [set_at pos value board] returns a NEW board with [value] at [pos].
    Lower-level function when if you have position and value separately. *)

val remove : Tile.Position.t -> t -> t
(** [remove pos board] returns a NEW board with position [pos] cleared.
    No-op if position was already empty. *)

val get : Tile.Position.t -> t -> Tile.Value.t option
(** [get pos board] returns [Some value] if position has a tile, [None] otherwise *)

val get_tile : Tile.Position.t -> t -> Tile.t option
(** [get_tile pos board] returns [Some tile] if position has a value.
    Reconstructs full Tile from position + value. *)

val mem : Tile.Position.t -> t -> bool
(** [mem pos board] returns true if position has a tile *)

(** {2 Navigation} *)

val get_up : Tile.Position.t -> t -> Tile.t option
(** Get full tile at position above *)

val get_down : Tile.Position.t -> t -> Tile.t option
(** Get full tile at position below *)

val get_right : Tile.Position.t -> t -> Tile.t option
(** Get full tile at position to the right *)

val get_left : Tile.Position.t -> t -> Tile.t option
(** Get full tile at position to the left *)

val get_neighbor : Tile.Position.t -> Direction.t -> t -> Tile.t option
(** Get full tile in given direction from position *)

val neighbors : Tile.Position.t -> t -> (Direction.t * Tile.t) list
(** Get all adjacent tiles with their directions *)

val has_neighbor : Tile.Position.t -> t -> bool
(** Check if position has at least one adjacent tile *)

(** {2 Tile Operations} *)

val place_tile : Tile.t -> t -> t
(** Alias for [set] - place a tile on the board *)

val place_tiles : Tile.t list -> t -> t
(** Place multiple tiles on board *)

val remove_tile : Tile.Position.t -> t -> (Tile.t * t) option
(** Remove tile at position, returning the removed tile and new board.
    Returns None if no tile at position. *)

val remove_tiles : Tile.Position.t list -> t -> (Tile.t list * t)
(** Remove multiple tiles, returning removed tiles and new board.
    Skips positions that don't have tiles. *)

val move_tile : Tile.Position.t -> Tile.Position.t -> t -> (t, string) result
(** [move_tile from_pos to_pos board] moves tile from one position to another.
    Returns Error if no tile at from_pos or to_pos is occupied. *)

(** {2 Collection Operations} *)

val to_tiles : t -> Tile.t list
(** Convert all positions and values to Tile list *)

val to_alist : t -> (Tile.Position.t * Tile.Value.t) list
(** Get all tiles as association list *)

val of_alist_exn : (Tile.Position.t * Tile.Value.t) list -> t
(** Create board from association list. Raises Errors (?) if duplicate positions. *)

val of_tiles : Tile.t list -> (t, string) result
(** Create board from tile list. Returns Error (?) if duplicate positions. *)

val of_tiles_exn : Tile.t list -> t
(** Create board from tile list. Raises errors (?) if duplicate positions. *)

val is_empty : t -> bool
(** Check if board has no tiles *)

val size : t -> int
(** Count of tiles on board *)

val fold : t -> init:'acc -> f:(key:Tile.Position.t -> data:Tile.Value.t -> 'acc -> 'acc) -> 'acc
(** Fold over all tiles on the board *)

val fold_tiles : t -> init:'acc -> f:(Tile.t -> 'acc -> 'acc) -> 'acc
(** Fold over all tiles *)

val iter : t -> f:(key:Tile.Position.t -> data:Tile.Value.t -> unit) -> unit
(** Iterate over all tiles on the board *)

val iter_tiles : t -> f:(Tile.t -> unit) -> unit
(** Iterate over all tiles (reconstructed as Tile.t) *)

val filter : t -> f:(key:Tile.Position.t -> data:Tile.Value.t -> bool) -> t
(** Keep only tiles that satisfy predicate *)

val map_values : t -> f:(Tile.Value.t -> Tile.Value.t) -> t
(** Transform all values on the board *)

(** {2 Spatial Queries} *)

val bounds : t -> (Tile.Position.t * Tile.Position.t) option
(** Get bounding box as (min_position, max_position).
    Returns None for empty board. *)

val positions : t -> Tile.Position.t list
(** Get all positions that have tiles *)

val values : t -> Tile.Value.t list
(** Get all values on the board *)

(** {2 Display} *)

val to_string : t -> string
(** ASCII representation of the board - mostly for debugging *)

include Sexpable.S with type t := t