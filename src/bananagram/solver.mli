open Lib

module Utils : sig type t end
module Hint : sig
    type t = {
        pos : Tile.Position.t;
        word : Banana_gram.Tile.Value.t list;
        across : bool
    }
end

(** [set_up_utils dict_filename dist_filename] returns a Utils.t object populated using the dictionary provided
    in file dict_filename and letter distribution provided in file dist_filename *)
val set_up_utils : string -> string -> Utils.t

(** [utils_as_str utils] returns string containing the value of utils *)
val utils_as_str : Utils.t -> string

(** [calculate_hint utils rack board] returns a spot - ( pos * word * across ) option - where pos is the start pos
    of the word. word is a Tile.Value.t list or None *)
val calculate_hint : Utils.t -> Banana_gram.Tile.Value.t list -> Banana_gram.board -> Hint.t option

(** [hint_as_string hint] returns a string message containing the info about the hint *)
val hint_as_string : Hint.t -> string