open Core

module Utils = struct
  module WordSet = Set.Make(struct type t = Banana_gram.word [@@deriving sexp, compare] end)
  module WordMap = Map.Make(struct type t = char list [@@deriving sexp, compare] end)
  module TileMap = Map.Make(struct type t = Banana_gram.tile [@@deriving sexp, compare] end)

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

let get_word_to_play (utils : Utils.t) (rack : Banana_gram.tile list) (seed : Banana_gram.tile list) : char list option =
  let rec search stack best best_score search_count =
    let max_words_per_spot = 300000 in
    (* break conditions *)
    if search_count = max_words_per_spot then best
    else if Stack.is_empty stack then best
    
    (* main search loop *)
    else begin
      (* get the next combination of tiles to try *)
      let so_far, checked_tiles_count = Stack.pop stack in
      (* how great would it be if we could make a word? *)
      let score = get_heuristic utils so_far seed in
      let new_best, new_best_score =
        if score > best_score then begin
          let word = check_for_word utils so_far in
          if word <> [] then (* we found a word that's better than previous best *)
            (Some word, score)
          else (* we didn't find word that's better than previous best *)
              (best, best_score)
        end else
          (best, best_score)
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
    end
  in
  let stack = Stack.create () in
  Stack.push (List.map seed ~f:(fun x -> (x, 0))) stack;
  search stack None 0 0

let check_for_word (utils : Utils.t) (tiles : Banana_gram.tile list) : Banana_gram.tile list =
  let sorted_base = List.sort Lib.Tile.compare tiles in
  match WordMap.find utils.anagram_map sorted_base with
  | None -> []
  | Some anagrams -> Set.nth_exn anagrams 0

let get_heuristics (utils : Utils.t) (word : Banana_gram.tile list) (seed : Banana_gram.tile list) : int =
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
let find_playable_spots (board : Banana_gram.board) (tiles_count : int) : (Banana_gram.tile * bool) list =
  List.fold (Board.to_tiles board) ~init:[] ~f:(
    fun found_spots tile ->
      let check_and_add_across spots tile =
        if checkHorizontalSpacing board (Tile.position tile) tiles_count then
          (tile, true) :: spots (* add valid spot (across=true) *)
        else spots (* don't add spot *)
      in
      let check_and_add_down spots tile =
        if checkVerticalSpacing board (Tile.position tile) tiles_count then
          (tile, false) :: spots (* add valid spot (across=true) *)
        else spots (* don't add spot *)
      in
      (* conditionally add across/down spots to found_spots *)
      check_and_add_down (check_and_add_across found_spots tile) tile
  )

(* check spacing to the left and right of a down-word *)
let checkHorizontalSpacing (board : Banana_gram.board) (pos : Lib.Tile.Position.t) (tiles_count : int) : bool =
  List.fold (List.init 3 ~f:(fun x -> x-1)) ~init:true ~f:(
  (* loop -1, 0, 1 *)
    fun ret dCol ->
      List.fold (List.init (tiles_count * 2 + 3)) ~f:(fun x -> x - tiles_count) ~init:ret ~f:(
      (* loop -tiles_count-1 .. tiles_count+1. Must check spacing all around tiles *)
        fun ret dRow ->
          let r, c = pos in
          let currPos = Tile.Position.create (r + dRow) (c + dCol) in
          match Lib.Board.get currPos board with
          | None -> ret (* if nothing there, then no worries. good. *)
          | Some _ -> 
            if dCol = 0 then
              ret (* don't care about tiles in row of origin tile as no new tiles can interfere *)
            else
              false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
        )
    )

(* check spacing to the up and down of an across-word *)
let checkVerticalSpacing (board : Banana_gram.board) (pos : Lib.Tile.Position.t) (tiles_count : int) : bool =
  List.fold (List.init 3 ~f:(fun x -> x-1)) ~init:true ~f:(
  (* loop -1, 0, 1 *)
    fun ret dRow ->
      List.fold (List.init (tiles_count * 2 + 3) ~f:(fun x -> x - tiles_count)) ~init:ret ~f:(
      (* loop -tiles_count-1 .. tiles_count+1. Must check spacing all around tiles *)
        fun ret dCol ->
          let r, c = pos in
          let currPos = Lib.Tile.Position.create (r + dRow) (c + dCol) in
          match Lib.Board.get currPos board with
          | None -> ret (* if nothing there, then no worries. good. *)
          | Some _ -> 
            if dRow = 0 then
              ret (* don't care about tiles in col of origin tile as no new tiles can interfere *)
            else
              false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
        )
    )