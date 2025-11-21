open Core

module Utils : sig type t end

val set_up_utils : Utils.t

val peek_random_tiles_from_bag : Tile.Value.t list -> int -> Tile.Value.t list
(** [peek_random_tiles_from_bag tile_bag count] returns [count] tiles from [tile_bag] *)

val remove_tiles_from_bag : Tile.Value.t list -> Tile.Value.t list -> Tile.Value.t list
(** [remove_tiles_from_bag tile_bag tiles] returns new tile_bag with [tiles] removed from it *)

val get_first_word : Utils.t -> Tile.Value.t list -> Word.t list
(** [get_first_word utils rack] returns word to play to start the board *)

val place_first_word_on_board : Board.t -> Word.t -> Board.t
(** [place_first_word_on_board board word] returns new board with word placed on it *)

val remove_tiles_from_rack : Tile.t list -> Tile.t list -> Tile.t list
(** [remove_tiles_from_rack rack tiles] returns new rack equal to old [rack] with [tiles] removed*)

val play_word_on_board : Utils.t -> Tile.t list -> Board.t -> (Board.t * Tile.t list) option
(** [play_word_on_board utils rack board] returns Some new board ([board] with added
    word made from [rack] tiles) AND new rack. Or None if no new word found *)