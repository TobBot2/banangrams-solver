open Core

(** Immutable board representation using a map from positions to tile values *)

type t [@@deriving sexp, compare]
(** The board type - a map from Position to Value *)

val empty : t
(** Create an empty board *)

val of_tiles : Tile.t list -> (t, string) result
(** Create board from tile list. Returns Error if duplicate positions. *)

val set : Tile.t -> t -> t
(** [set tile board] returns a NEW board with [tile] placed at its position.
    Overwrites if position already occupied. *)

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

val to_tiles : t -> Tile.t list
(** Convert all positions and values to Tile list *)

val positions : t -> Tile.Position.t list
(** Get all positions that have tiles *)

val is_empty : t -> bool
(** Check if board has no tiles *)

val size : t -> int
(** Count of tiles on board *)
