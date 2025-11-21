open Core

module Utils = struct
  module WordSet = Set.Make(struct type t = Word.t [@@deriving sexp, compare] end)
  module WordMap = Map.Make(struct type t = Word.t [@@deriving sexp, compare] end)
  module TileMap = Map.Make(struct type t = Tile.t [@@deriving sexp, compare] end)

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
    word made from [rack] tiles) AND new rack. Or None if no new word found *)
let play_word_on_board utils rack board =
  let playable_spots = find_playable_spots board (List.length rack) in
  (* best spot = tuple ( pos * word * score ) *)
  let best_spot = List.fold playable_spots ~init:None ~f:(
  fun curr_best_spot candidate =
    let pos, across = candidate in
    let seed = [ Board.get pos ]
    let word = get_word_to_play utils rack seed in
    match word with
    | None -> curr_best_spot (* no word to play... propagate current best spot *)
    | Some w -> (* word to play! Let's see if it's better than current best... *)
      let score = get_heuristics utils word seed in
      match curr_best_spot with
      | None -> (Some pos ; w ; score) (* if no current best, then this word is current best*)
      | Some s -> 
        let best_pos, best_score = s in
        if score > best_score then
          Some (Some pos ; w ; score)
        else
          curr_best_spot
  ) in
  match best_spot with
  | None -> None
  | Some spot ->
    let pos, word, score = spot in
    let seed = [ Board.get pos ] in
    failwith "TODO"
    (* let tiles_used = word remove seed
    remove tiles used from rack
    update board to include tiles
    return new board and new rack *)


(* ********************************************** *)
(*           HELPER FUNCTIONS (private)           *)
(* ********************************************** *)

let get_word_to_play (utils : Utils.t) (rack : Tile.t list) (seed : Tile.t list) : Word.t option =
  failwith "TODO"

let get_heuristics (utils : Utils.t) (word : Word.t) (seed : Tile.t list) : int =
  failwith "TODO"

(* return list of playable spots (spot = position * is_across) *)
let find_playable_spots (board : Board.t) (tiles_count : int) : (Tile.t * bool) list =
  List.fold (Board.to_tiles board) ~init:[] ~f:(
    fun found_spots tile ->
      let check_and_add_across spots tile =
        if checkHorizontalSpacing board (Tile.position tile) tiles_count then
          (tile ; true) :: spots
      in
      let check_and_add_down spots tile =
        if checkVerticalSpacing board (Tile.position tile) tiles_count then
          (tile ; false) :: spots
      in
      (* conditionally add across/down spots to found_spots *)
      check_and_add_down (check_and_add_across found_spots tile) tile
  )

(* check spacing to the left and right of a down-word *)
let checkHorizontalSpacing (board : Board.t) (pos : Tile.Position.t) (tiles_count : int) : bool =
  List.fold (List.init 3 ~f:(fun x -> x-1)) ~init:true ~f:(
  (* loop -1, 0, 1 *)
  fun ret dCol ->
    List.fold (List.init (tiles_count * 2 + 3)) ~f:(fun x -> x - tiles_count) ~init:ret ~f:(
    (* loop -tiles_count-1 .. tiles_count+1. Must check spacing all around tiles *)
    fun ret dRow ->
      let r, c = pos in
      let currRow = r + dRow in
      let currCol = c + dCol in
      match Board.get (currRow ; currCol) board with
      | None -> ret (* if nothing there, then good, no worries *)
      | Some tile -> 
        if dCol = 0 then
          ret (* don't care about tiles in row of origin tile as no new tiles can interfere *)
        else
          false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
    )
  )

(* check spacing to the up and down of an across-word *)
let checkVerticalSpacing (board : Board.t) (pos : Tile.Position.t) (tiles_count : int) : bool =
  List.fold (List.init 3 ~f:(fun x -> x-1)) ~init:true ~f:(
  (* loop -1, 0, 1 *)
  fun ret dRow ->
    List.fold (List.init (tiles_count * 2 + 3)) ~f:(fun x -> x - tiles_count) ~init:ret ~f:(
    (* loop -tiles_count-1 .. tiles_count+1. Must check spacing all around tiles *)
    fun ret dCol ->
      let r, c = pos in
      let currRow = r + dRow in
      let currCol = c + dCol in
      match Board.get (currRow ; currCol) board with
      | None -> ret (* if nothing there, then good, no worries *)
      | Some tile -> 
        if dRow = 0 then
          ret (* don't care about tiles in col of origin tile as no new tiles can interfere *)
        else
          false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
    )
  )