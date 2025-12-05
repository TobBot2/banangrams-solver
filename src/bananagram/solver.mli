open Core

module Utils : sig type t end

val set_up_utils : Utils.t

(** [calculate_hint utils rack board] returns a spot - ( pos * word * across ) option - where pos is the start pos
    of the word. word is a Tile.Value.t list or None *)
val calculate_hint : Utils.t -> Tile.t list -> Board.t -> (Tile.Position.t * Tile.t list option * bool) option