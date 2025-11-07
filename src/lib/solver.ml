open Core

module Utils = struct
  module WordSet = Set.Make(struct type t = Word.t [@@deriving sexp, compare] end)
  module WordMap = Map.Make(struct type t = Word.t [@@deriving sexp, compare] end)
  module TileMap = Map.Make(struct type t = Tile.t [@@deriving sex, compare] end)

  type t = {
    anagram_map : WordSet.t WordMap.t;
    letter_scores : int TileMap.t;
  }
end

(** [peek_random_tiles_from_bag tile_bag count] returns [count] tiles from [tile_bag] *)
let peek_random_tiles_from_bag tile_bag count =
  (* generate random indices to pull from *)
  let rand_indices = List.init count ~f:(fun _ -> Random.int (List.length tile_bag)) in
  (* loop through tiles, accumulating if index matches a randomly generated one *)
  List.foldi tile_bag ~init:[] ~f:(fun i acc tile ->
    if List.exists rand_indices ~f:(fun idx -> idx = i) then tile :: acc
    else acc
  )

(** [get_first_word utils rack] returns word to play to start the board *)
let get_first_word utils rack =
  get_word_to_play utils rack []

(** [place_first_word_on_board board word] returns new board with word placed on it *)
let place_first_word_on_board board word =
  List.fold word ~init:board ~f:(fun board' tile ->
    Board.set tile board'
  )

(** [remove_tiles_from_rack rack tiles] returns new rack equal to old [rack] with [tiles] removed *)
let remove_tiles_from_rack rack tiles =
  let rec remove_one tile lst =
    match lst with
    | [] -> failwith "remove_tiles_from_rack [ERROR] :: Tile not found in rack"
    | hd :: tl ->
      if hd = tile then tl
      else hd :: remove_one tile tl
  in
  List.fold tiles ~init:rack ~f:(fun acc tile -> remove_one tile acc)

(** [play_word_on_board utils rack board] returns Some new board ([board] with added
    word made from [rack] tiles). Or None if no new word found *)
let play_word_on_board utils rack board =
  failwith "TODO"

(* ********************************************** *)
(*           HELPER FUNCTIONS (private)           *)
(* ********************************************** *)

let get_word_to_play (utils : Utils.t) (rack : Tile.t list) (seed : Tile.t list) : Word.t =
  failwith "TODO"

