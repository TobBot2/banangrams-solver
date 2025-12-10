open Core

(* implementation based on https://web.stanford.edu/class/archive/cs/cs106b/cs106b.1172/handouts/bananagrams.html *)

module Utils = struct
  module WordSet = Set.Make(struct type t = Banana_gram.Tile.Value.t list [@@deriving sexp, compare] end)
  module WordMap = Map.Make(struct type t = Banana_gram.Tile.Value.t list [@@deriving sexp, compare] end)
  module ScoreMap = Map.Make(struct type t = Banana_gram.Tile.Value.t [@@deriving sexp, compare] end)

  type t = {
    anagram_map : WordSet.t WordMap.t;
    letter_scores : int ScoreMap.t;
  }

end

module Hint = struct
    type t = {
        pos : Lib.Tile.Position.t;
        word : Banana_gram.Tile.Value.t list;
        across : bool
    }
end

(* ********************************************** *)
(*         HELPER FUNCTION IMPLEMENTATIONS        *)
(* ********************************************** *)

(* HELPERS FOR set_up_utils *)

let score_tile_value (v : Banana_gram.Tile.Value.t) (count : int) : int =
  match Banana_gram.Tile.Value.to_string v with
  | "A" | "E" | "I" | "O" | "U" -> 1
  | _ -> 
    if count <= 2 then 40
    else if count <= 4 then 10
    else if count <= 9 then 5
    else 3

let get_words (dict_filename : string) : Banana_gram.Tile.Value.t list list =
  In_channel.create dict_filename
  |> In_channel.fold_lines ~init:[] ~f:(
    fun ls word ->
      let upper = String.uppercase word in
      let word_as_char_ls = String.to_list upper in
      word_as_char_ls :: ls
  )

let create_anagram_map (words : Banana_gram.Tile.Value.t list list) : Utils.WordSet.t Utils.WordMap.t =
  List.fold words ~init:Utils.WordMap.empty ~f:(
    fun map word ->
      let sorted_word = List.sort word ~compare:Banana_gram.Tile.Value.compare in
      Map.update map sorted_word ~f:(
        fun anagrams ->
          match anagrams with
          | None -> Utils.WordSet.of_list [word]
          | Some anagrams_set -> Set.add anagrams_set word
      )
  )

let create_letter_scores_map (distribution_filename : string) : int Utils.ScoreMap.t =
  (* make list of letters to loop through *)
  (* probably should be looping through list of valid tile values, not creating list *)
  let letters = List.init 26 ~f:(
    fun i ->
      let a_int = Char.to_int 'A' in
      Char.of_int_exn @@ i + a_int
    )
  in

  (* loop through letters (and concurrently lines in distribution file), adding scores to map *)
  let in_file = In_channel.create distribution_filename in
  List.fold letters ~init:Utils.ScoreMap.empty ~f:(
    fun map letter ->
      let data =
        let count =
          In_channel.input_line_exn in_file
          |> String.split ~on:' '
          |> List.hd_exn
          |> Int.of_string in
        score_tile_value letter count
      in
      Map.set map ~key:letter ~data
    )

(* HELPERS FOR calculate_hint *)

(* check spacing to the left and right of a down-word *)
let checkHorizontalSpacing (board : Banana_gram.board) (pos : Lib.Tile.Position.t) (tiles_count : int) : bool =
  List.fold (List.init 3 ~f:(fun x -> x-1)) ~init:true ~f:(
  (* loop -1, 0, 1 *)
    fun ret dCol ->
      List.fold (List.init (tiles_count * 2 + 3) ~f:(fun x -> x - tiles_count)) ~init:ret ~f:(
      (* loop -tiles_count-1 .. tiles_count+1. Must check spacing all around tiles *)
        fun ret dRow ->
          let r, c = pos in
          let currPos = Lib.Tile.Position.create (r + dRow) (c + dCol) in
          match Banana_gram.Board.get currPos board with
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
          match Banana_gram.Board.get currPos board with
          | None -> ret (* if nothing there, then no worries. good. *)
          | Some _ -> 
            if dRow = 0 then
              ret (* don't care about tiles in col of origin tile as no new tiles can interfere *)
            else
              false (* if there's a tile in the spacing around where the new word should go, propagate false as ret. *)
        )
    )

(* return list of playable spots (spot = position * is_across) *)
let find_playable_spots (board : Banana_gram.board) (tiles_count : int) : (Lib.Tile.Position.t * bool) list =
  List.fold (Banana_gram.Board.to_tiles board) ~init:[] ~f:(
    fun found_spots tile ->
      let check_and_add_across spots tile =
        let pos = Banana_gram.Tile.position tile in
        if checkHorizontalSpacing board pos tiles_count then
          (pos, true) :: spots (* add valid spot (across=true) *)
        else spots (* don't add spot *)
      in
      let check_and_add_down spots tile =
        let pos = Banana_gram.Tile.position tile in
        if checkVerticalSpacing board pos tiles_count then
          (pos, false) :: spots (* add valid spot (across=false) *)
        else spots (* don't add spot *)
      in
      (* conditionally add across/down spots to found_spots *)
      check_and_add_down (check_and_add_across found_spots tile) tile
  )

let check_for_word (utils : Utils.t) (tiles : Banana_gram.Tile.Value.t list) : Banana_gram.Tile.Value.t list =
  let sorted_base = List.sort ~compare:Banana_gram.Tile.Value.compare tiles in
  match Map.find utils.anagram_map sorted_base with
  | None -> []
  | Some anagrams -> List.nth_exn (Set.to_list anagrams) 0

let get_heuristics (utils : Utils.t) (word : Banana_gram.Tile.Value.t list) (seed : Banana_gram.Tile.Value.t list) : int =
  (* remove seed (already placed tiles) from word *)
  let used_letters = 
    let rec remove_one tile lst =
      match lst with
      | [] ->
        printf "\nword:%s\nseed:%s" (String.of_char_list word) (String.of_char_list seed);
        failwith "[ERROR] >> word doesn't contain seed somehow?"
      | hd :: tl ->
        if Banana_gram.Tile.Value.equal hd tile then tl
        else hd :: remove_one tile tl
    in
    List.fold seed ~init:word ~f:(fun acc tile -> remove_one tile acc)
  in

  (* get score for the would-be-used tiles by playing the word *)
  List.fold used_letters ~init:0 ~f:(
    fun score ch ->
      score + (Map.find_exn utils.letter_scores ch)
  )

let get_word_to_play (utils : Utils.t) (rack : Banana_gram.Tile.Value.t list) (seed : Banana_gram.Tile.Value.t list) : Banana_gram.Tile.Value.t list option =
  let rec search stack best best_score search_count =
    let max_words_per_spot = 300000 in
    (* break conditions *)
    if search_count = max_words_per_spot then best
    else if Stack.is_empty stack then best
    
    (* main search loop *)
    else begin
      (* get the next combination of tiles to try *)
      let so_far, checked_tiles_count = Stack.pop_exn stack in
      (* how great would it be if we could make a word? *)
      let score = get_heuristics utils so_far seed in
      let new_best, new_best_score =
        if score > best_score then begin
          let word = check_for_word utils so_far in
          match word with
          | [] -> (best, best_score) (* we didn't find word that's better than previous best *)
          | _ -> (Some word, score) (* we found a word that's better than previous best *)
        end else
          (best, best_score)
      in

      (* what is the next tile to include or exclude? *)
      if checked_tiles_count < List.length rack then begin
        (* try including it *)
        let tile_char = List.nth_exn rack checked_tiles_count in
        let so_far_incl = so_far @ [tile_char] in
        Stack.push stack (so_far_incl, checked_tiles_count + 1);
        (* try excluding it *)
        let so_far_excl = so_far in
        Stack.push stack (so_far_excl, checked_tiles_count + 1);
      end;

      search stack new_best new_best_score (search_count + 1)
    end
  in
  let stack = Stack.create () in
  let _ = List.for_all seed ~f:(fun x ->
    Stack.push stack ([x], 0);
    true (* loop through all unconditionally *)
  ) in
  search stack None 0 0

(* ********************************************** *)
(*          PUBLIC FUNCTION IMPLEMENTATION        *)
(* ********************************************** *)

(** [set_up_utils dict_filename dist_filename] returns a Utils.t object populated using the dictionary provided
    in file dict_filename and letter distribution provided in file dist_filename *)
let set_up_utils dict_filename dist_filename =
  let anagram_map = get_words dict_filename |> create_anagram_map in
  let letter_scores = create_letter_scores_map dist_filename in
  { Utils.anagram_map=anagram_map; Utils.letter_scores=letter_scores }

(** [utils_as_str utils] returns string containing the value of utils *)
let utils_as_str utils =
  let anagrams_str =
    utils.Utils.anagram_map
    |> Map.to_alist
    |> List.map ~f:(fun (word, anagrams) -> 
      (word |> List.to_string ~f:Banana_gram.Tile.Value.to_string) ^ " -> " ^ 
      (anagrams |> Set.to_list |> List.map ~f:(fun w -> w |> List.to_string ~f:Banana_gram.Tile.Value.to_string) |> String.concat ~sep:", ")
    )
    |> String.concat ~sep:"\n"
  in
  let anagrams = "\n\n**********************************\nANAGRAMS MAP\n\n" ^ anagrams_str ^ "\n\n" in

  let letter_scores_str =
    utils.Utils.letter_scores
    |> Map.to_alist
    |> List.map ~f:(fun (letter, score) ->
      (String.of_char letter) ^ " -> " ^
      (score |> Int.to_string)
    )
    |> String.concat ~sep:"\n"
  in
  let letter_scores = "\n\n**********************************\nLETTER SCORES\n\n" ^ letter_scores_str ^ "\n\n" in

  anagrams ^ letter_scores

(** [calculate_hint utils rack board] returns a spot - ( pos * word * across ) option - where pos is the start pos
    of the word. word is a Tile.Value.t list or None *)
let calculate_hint utils rack board =
  let playable_spots = find_playable_spots board (List.length rack) in
  let best_spot = List.fold playable_spots ~init:None ~f:(
    fun curr_best_spot candidate ->
      let pos, across = candidate in
      let seed = [ Banana_gram.Board.get pos board |> Option.value_exn ] in
      let word = get_word_to_play utils rack seed in
      match word with
      | None -> curr_best_spot (* no word to play... propagate current best spot *)
      | Some w -> (* word to play! Let's see if it's better than current best... *)
        let score = get_heuristics utils w seed in
        match curr_best_spot with
        | None -> Some (pos, w, score, across) (* if no current best, then this word is current best *)
        | Some s -> 
          let _, _, best_score, _ = s in (* only compare scores *)
          if score > best_score then
            Some (pos, w, score, across)
          else
            curr_best_spot
    )
  in
  (* return the best spot (or None)*)
  match best_spot with
  | None -> None
  | Some spot ->
    let pos, word, _, across = spot in
    Some { Hint.pos=pos; Hint.word=word; Hint.across=across }


(** [hint_as_string hint] returns a string message containing the info about the hint *)
let hint_as_string hint =
    let pos_text = Lib.Tile.Position.to_string hint.Hint.pos in
    let word_text = String.of_char_list hint.Hint.word in
    let direction_text = if hint.Hint.across then "across" else "down" in
    "You should play " ^ word_text ^ " going " ^ direction_text ^ " at " ^ pos_text
