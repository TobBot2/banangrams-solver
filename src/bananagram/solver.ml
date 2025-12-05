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

(* implementation based on https://web.stanford.edu/class/archive/cs/cs106b/cs106b.1172/handouts/bananagrams.html *)

(** [calculate_hint utils rack board] returns a spot - ( pos * word * across ) option - where pos is the start pos
    of the word. word is a Tile.Value.t list or None *)
let calculate_hint utils rack board =
  let playable_spots = find_playable_spots board (List.length rack) in
  let best_spot = List.fold playable_spots ~init:None ~f:(
    fun curr_best_spot candidate ->
      let pos, across = candidate in
      let seed = [ Board.get pos board ] in
      let word = get_word_to_play utils rack seed in
      match word with
      | None -> curr_best_spot (* no word to play... propagate current best spot *)
      | Some w -> (* word to play! Let's see if it's better than current best... *)
        let score = get_heuristics utils word seed in
        match curr_best_spot with
        | None -> Some (pos, word, score, across) (* if no current best, then this word is current best *)
        | Some s -> 
          let _, _, best_score, _ = s in (* only compare scores *)
          if score > best_score then
            Some (pos, word, score, across)
          else
            curr_best_spot
    )
  in
  (* return the best spot (or None)*)
  match best_spot with
  | None -> None
  | Some spot ->
    let pos, word, _, across = spot in
    Some ( pos, word, across )


(* ********************************************** *)
(*           HELPER FUNCTIONS (private)           *)
(* ********************************************** *)

let get_word_to_play (utils : Utils.t) (rack : Tile.t list) (seed : Tile.t list) : Tile.Value.t list option =
  let rec search stack best best_score search_count =
    let max_words_per_spot = 300000 in
    (* break conditions *)
    if search_count = max_words_per_spot then best
    else if Stack.is_empty stack then best
    
    (* main search loop *)
    else
      (* get the next combination of tiles to try *)
      let so_far, checked_tiles_count = Stack.pop stack in
      (* how great would it be if we could make a word? *)
      let score = get_heuristic utils so_far seed in
      let (new_best, new_best_score) =
        if score > best_score then begin
          let word = check_for_word utils so_far in
          (* we found a word that's better than previous best *)
          if word <> [] then (Some word, score)
          (* we didn't find word that's better than previous best *)
          else (best, best_score)
        end else (best, best_score)
      in

      (* what is the next tile to include or exclude? *)
      if checked_tiles_count < List.length rack then begin
        (* try including it *)
        let tile_char = List.nth rack checked_tiles_count in
        let a = so_far @ [tile_char] in
        Stack.push (a, checked_tiles_count + 1) stack;
        (* try excluding it *)
        let b = so_far in
        Stack.push (b, checked_tiles_count + 1) stack;
      end;

      search stack new_best new_best_score (search_count + 1)
  in
  let stack = Stack.create () in
  Stack.push (List.map seed ~f:(fun x -> (x, 0))) stack;
  search stack None 0 0

let check_for_word (utils : Utils.t) (tiles : Tile.t list) : Tile.t list =
  let sorted_base = List.sort Tile.compare tiles in
  match WordMap.find utils.anagram_map sorted_base with
  | None -> []
  | Some anagrams -> Set.nth_exn anagrams 0

let get_heuristics (utils : Utils.t) (word : Tile.t list) (seed : Tile.t list) : int =
  (* remove seed (already placed tiles) from word *)
  let used_letters = remove_tiles_from_pool word seed in

  (* get score for the would-be-used tiles by playing the word *)
  List.fold used_letters ~init:0 ~f:(
    fun score ch ->
      score + (TileMap.get utils.letter_scores ch)
  )

let remove_tiles_from_pool pool tiles =
  let rec remove_one tile lst =
    match lst with
    | [] -> failwith "remove_tiles_from_pool [ERROR] :: Tile not found in pool"
    | hd :: tl ->
      if hd = tile then tl
      else hd :: remove_one tile tl
  in
  List.fold tiles ~init:pool ~f:(fun acc tile -> remove_one tile acc)

(* return list of playable spots (spot = position * is_across) *)
let find_playable_spots (board : Board.t) (tiles_count : int) : (Tile.t * bool) list =
  List.fold (Board.to_tiles board) ~init:[] ~f:(
    fun found_spots tile ->
      let check_and_add_across spots tile =
        if checkHorizontalSpacing board (Tile.position tile) tiles_count then
          (tile ; true) :: spots
        else spots
      in
      let check_and_add_down spots tile =
        if checkVerticalSpacing board (Tile.position tile) tiles_count then
          (tile ; false) :: spots
        else spots
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
          let currPos = Tile.Position.create (r + dRow) (c + dCol) in
          match Board.get currPos board with
          | None -> ret (* if nothing there, then no worries. good. *)
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
          let currPos = Tile.Position.create (r + dRow) (c + dCol) in
          match Board.get currPos board with
          | None -> ret (* if nothing there, then no worries. good. *)
          | Some tile -> 
            if dRow = 0 then
              ret (* don't care about tiles in col of origin tile as no new tiles can interfere *)
            else
              false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
        )
    )