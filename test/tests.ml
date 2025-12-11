open Core 
open OUnit2
open Lib
open Bananagram  (* Open the bananagram library which has instantiated modules *)

(* Position tests - Position is in the Lib module *)
let test_position_create _ =
  let pos = Lib.Tile.Position.create 5 10 in
  assert_equal 5 (Lib.Tile.Position.row pos);
  assert_equal 10 (Lib.Tile.Position.col pos)

let test_position_up _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let up_pos = Lib.Tile.Position.up pos in
  assert_equal 6 (Lib.Tile.Position.row up_pos);  
  assert_equal 10 (Lib.Tile.Position.col up_pos)

let test_position_down _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let down_pos = Lib.Tile.Position.down pos in
  assert_equal 4 (Lib.Tile.Position.row down_pos); 
  assert_equal 10 (Lib.Tile.Position.col down_pos)

let test_position_right _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let right_pos = Lib.Tile.Position.right pos in
  assert_equal 5 (Lib.Tile.Position.row right_pos);
  assert_equal 11 (Lib.Tile.Position.col right_pos)

let test_position_left _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let left_pos = Lib.Tile.Position.left pos in
  assert_equal 5 (Lib.Tile.Position.row left_pos);
  assert_equal 9 (Lib.Tile.Position.col left_pos)  

(* Tile tests - use Banana_gram.Tile (the instantiated version) *)
let test_tile_create _ =
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 3 4) 'A' in
  assert_equal 3 (Lib.Tile.Position.row (Banana_gram.Tile.position tile));
  assert_equal 4 (Lib.Tile.Position.col (Banana_gram.Tile.position tile));
  assert_equal 'A' (Banana_gram.Tile.value tile)

let test_tile_to_string _ =
  (* Test the string representation of a tile *)
  let pos = Lib.Tile.Position.create 3 5 in
  let tile = Banana_gram.Tile.create pos 'Z' in
  let tile_str = Banana_gram.Tile.to_string tile in
  (* Should be "Z@(3,5)" *)
  assert_equal "Z@(3,5)" tile_str

(* Word tests - use Banana_gram.Word (the instantiated version) *)
let test_word_create _ =
  let start_pos = Lib.Tile.Position.create 0 0 in
  let word = Banana_gram.Word.create start_pos ['H'; 'I'] in
  assert_equal 2 (Banana_gram.Word.length word);
  assert_equal ['H'; 'I'] (Banana_gram.Word.values word);
  assert_equal "HI" (Banana_gram.Word.to_string word)

let test_word_start _ =
  let start_pos = Lib.Tile.Position.create 5 10 in
  let word = Banana_gram.Word.create start_pos ['C'; 'A'; 'T'] in
  let word_start = Banana_gram.Word.start word in
  assert_equal 5 (Lib.Tile.Position.row word_start);
  assert_equal 10 (Lib.Tile.Position.col word_start)


let test_word_to_string _ =
  let word = Banana_gram.Word.create (Lib.Tile.Position.create 0 0) ['D'; 'O'; 'G'] in
  assert_equal "DOG" (Banana_gram.Word.to_string word)

let test_word_is_empty_true _ =
  (* Test that an empty list is recognized as empty *)
  let empty_word = [] in
  assert_bool "empty word should be empty" (Banana_gram.Word.is_empty empty_word)

let test_word_is_empty_false _ =
  (* Test that a non-empty word is not empty *)
  let pos = Lib.Tile.Position.create 0 0 in
  let word = Banana_gram.Word.create pos ['A'] in
  assert_bool "non-empty word should not be empty" (not (Banana_gram.Word.is_empty word))

(* Board tests *)

let make_tile row col char =
  Banana_gram.Tile.create (Lib.Tile.Position.create row col) char
let test_board_empty _ =
  let board = Banana_gram.Board.empty in
  assert_bool "empty board should be empty" (Banana_gram.Board.is_empty board);
  assert_equal 0 (Banana_gram.Board.size board)

let test_board_set_get _ =
  let board = Banana_gram.Board.empty in
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 0 0)'X' in
  let board = Banana_gram.Board.set tile board in
  assert_equal (Some 'X') (Banana_gram.Board.get (Lib.Tile.Position.create 0 0) board)

let test_board_mem _ =
  let board = Banana_gram.Board.empty in
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'Z' in
  let board = Banana_gram.Board.set tile board in
  assert_bool "position should be occupied" 
    (Banana_gram.Board.mem (Lib.Tile.Position.create 5 5) board);
  assert_bool "position should not be occupied" 
    (not (Banana_gram.Board.mem (Lib.Tile.Position.create 5 6) board))

let test_board_of_tiles_success _ =
  (* Test creating a board from a list of tiles with no duplicates *)
  let tiles = [
    make_tile 0 0 'A';
    make_tile 0 1 'B';
    make_tile 1 0 'C';
  ] in
  
  match Banana_gram.Board.of_tiles tiles with
  | Ok board ->
      assert_equal 3 (Banana_gram.Board.size board);
      assert_equal (Some 'A') (Banana_gram.Board.get (Lib.Tile.Position.create 0 0) board);
      assert_equal (Some 'B') (Banana_gram.Board.get (Lib.Tile.Position.create 0 1) board);
      assert_equal (Some 'C') (Banana_gram.Board.get (Lib.Tile.Position.create 1 0) board)
  | Error msg ->
      assert_failure ("Should succeed but got error: " ^ msg)

let test_board_of_tiles_duplicate_error _ =
  (* Test that of_tiles returns an error when there are duplicate positions *)
  let tiles = [
    make_tile 0 0 'A';
    make_tile 0 1 'B';
    make_tile 0 0 'C';  (* Duplicate position (0,0) *)
  ] in
  
  match Banana_gram.Board.of_tiles tiles with
  | Ok _ ->
      assert_failure "Should return error for duplicate positions"
  | Error msg ->
      (* Check that error message mentions duplicate and the position *)
      assert_bool "error should mention 'Duplicate'" (String.contains msg 'D');
      assert_bool "error should mention position" (String.contains msg '(')

let test_board_of_tiles_empty _ =
  (* Test creating a board from an empty list of tiles *)
  match Banana_gram.Board.of_tiles [] with
  | Ok board ->
      assert_bool "should be empty" (Banana_gram.Board.is_empty board);
      assert_equal 0 (Banana_gram.Board.size board)
  | Error msg ->
      assert_failure ("Should succeed with empty list but got error: " ^ msg)

let test_board_to_tiles _ =
  (* Test converting a board back to a list of tiles *)
  let board = Banana_gram.Board.empty in
  let board = Banana_gram.Board.set (make_tile 0 0 'X') board in
  let board = Banana_gram.Board.set (make_tile 1 1 'Y') board in
  let board = Banana_gram.Board.set (make_tile 2 2 'Z') board in
  
  let tiles = Banana_gram.Board.to_tiles board in
  
  (* Should have 3 tiles *)
  assert_equal 3 (List.length tiles);
  
  (* Check that all original values are present *)
  let values = List.map ~f:Banana_gram.Tile.value tiles in
  let sorted_values = List.sort ~compare:Char.compare values in
  assert_equal ['X'; 'Y'; 'Z'] sorted_values

let test_board_to_tiles_empty _ =
  (* Test to_tiles on an empty board *)
  let board = Banana_gram.Board.empty in
  let tiles = Banana_gram.Board.to_tiles board in
  
  assert_equal 0 (List.length tiles)

let test_board_remove _ =
  (* Test removing a tile from the board *)
  let board = Banana_gram.Board.empty in
  let pos1 = Lib.Tile.Position.create 0 0 in
  let pos2 = Lib.Tile.Position.create 0 1 in
  
  let board = Banana_gram.Board.set (make_tile 0 0 'A') board in
  let board = Banana_gram.Board.set (make_tile 0 1 'B') board in
  
  (* Board should have 2 tiles *)
  assert_equal 2 (Banana_gram.Board.size board);
  assert_bool "position (0,0) should be occupied" (Banana_gram.Board.mem pos1 board);
  
  (* Remove tile at (0,0) *)
  let board = Banana_gram.Board.remove pos1 board in
  
  (* Board should now have 1 tile *)
  assert_equal 1 (Banana_gram.Board.size board);
  assert_bool "position (0,0) should not be occupied" (not (Banana_gram.Board.mem pos1 board));
  assert_bool "position (0,1) should still be occupied" (Banana_gram.Board.mem pos2 board);
  assert_equal (Some 'B') (Banana_gram.Board.get pos2 board)

let test_board_remove_nonexistent _ =
  (* Test removing a position that doesn't exist (should be a no-op) *)
  let board = Banana_gram.Board.empty in
  let board = Banana_gram.Board.set (make_tile 0 0 'X') board in
  
  let size_before = Banana_gram.Board.size board in
  
  (* Remove a position that doesn't exist *)
  let board = Banana_gram.Board.remove (Lib.Tile.Position.create 5 5) board in
  
  (* Size should be unchanged *)
  assert_equal size_before (Banana_gram.Board.size board);
  (* Original tile should still be there *)
  assert_equal (Some 'X') (Banana_gram.Board.get (Lib.Tile.Position.create 0 0) board)

let test_board_roundtrip _ =
  (* Test that to_tiles -> of_tiles is a roundtrip *)
  let original_tiles = [
    make_tile 0 0 'H';
    make_tile 0 1 'I';
    make_tile 1 0 'Y';
    make_tile 1 1 'A';
  ] in
  
  (* Create board from tiles *)
  let board = match Banana_gram.Board.of_tiles original_tiles with
    | Ok b -> b
    | Error msg -> assert_failure ("Failed to create board: " ^ msg)
  in
  
  (* Convert back to tiles *)
  let roundtrip_tiles = Banana_gram.Board.to_tiles board in
  
  (* Should have same number of tiles *)
  assert_equal (List.length original_tiles) (List.length roundtrip_tiles);
  
  (* Recreate board from roundtrip tiles *)
  let board2 = match Banana_gram.Board.of_tiles roundtrip_tiles with
    | Ok b -> b
    | Error msg -> assert_failure ("Failed to recreate board: " ^ msg)
  in
  
  (* Both boards should have same size *)
  assert_equal (Banana_gram.Board.size board) (Banana_gram.Board.size board2)


(*Validation tests*)
let test_valid_horizontal _ = 
  let board = Banana_gram.Board.empty in
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'W' in
  let tile1 = Banana_gram.Tile.create (Lib.Tile.Position.create 6 5) 'H' in
  let tile2 = Banana_gram.Tile.create (Lib.Tile.Position.create 7 5) 'A' in
  let tile3 = Banana_gram.Tile.create (Lib.Tile.Position.create 8 5) 'T' in
  let tile4 = Banana_gram.Tile.create (Lib.Tile.Position.create 0 0) 'T' in
  let board = Banana_gram.Board.set tile board in
  let board = Banana_gram.Board.set tile1 board in
  let board = Banana_gram.Board.set tile2 board in
  let board = Banana_gram.Board.set tile3 board in
  assert_bool "horizontal word should be connected" (Validation.is_connected board);
  let board = Banana_gram.Board.set tile4 board in
  let tiles = [tile; tile1; tile2; tile3] in
  assert_bool "horizontal word is valid"
    (Validation.is_word_start_horizontal (Lib.Tile.Position.create 5 5) board);
  assert_bool "horizontal tile is not valid"
    (not (Validation.is_word_start_horizontal (Lib.Tile.Position.create 6 5) board));
  assert_bool "single tile should not be a word start"
    (not (Validation.is_word_start_horizontal (Lib.Tile.Position.create 0 0) board));
  assert_bool "empty position should not be a word start"
    (not (Validation.is_word_start_horizontal (Lib.Tile.Position.create 3 3) board));
  assert_bool "position with left neighbor should not be word start"
    (not (Validation.is_word_start_horizontal (Lib.Tile.Position.create 6 5) board));
  assert_equal
    (Validation.extract_word_horizontal (Lib.Tile.Position.create 5 5) board) (Some tiles)
  

let test_valid_vertical _ = 
  let board = Banana_gram.Board.empty in
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'W' in
  let tile1 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 4) 'H' in
  let tile2 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 3) 'A' in
  let tile3 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 2) 'T' in
  let tile4 = Banana_gram.Tile.create (Lib.Tile.Position.create 0 0) 'T' in
  let board = Banana_gram.Board.set tile board in
  let board = Banana_gram.Board.set tile1 board in
  let board = Banana_gram.Board.set tile2 board in
  let board = Banana_gram.Board.set tile3 board in
  assert_bool "vertical word should be connected" (Validation.is_connected board);
  let board = Banana_gram.Board.set tile4 board in
  let tiles = [tile; tile1; tile2; tile3] in
  assert_bool "vertical word is valid"
    (Validation.is_word_start_vertical_down (Lib.Tile.Position.create 5 5) board);
  assert_bool "vertical tile is not valid"
    (not (Validation.is_word_start_vertical_down (Lib.Tile.Position.create 5 4) board));
  assert_bool "single tile should not be a vertical word start"
    (not (Validation.is_word_start_vertical_down (Lib.Tile.Position.create 0 0) board));
  assert_bool "position with up neighbor should not be word start"
    (not (Validation.is_word_start_vertical_down (Lib.Tile.Position.create 5 4) board));
  assert_equal
    (Validation.extract_word_vertical_down (Lib.Tile.Position.create 5 5) board) (Some tiles);
  assert_bool "separate tiles should not be connected" 
    (not (Validation.is_connected board))
  

let test_valid_extract_all _ = 
  let board = Banana_gram.Board.empty in
  let words = Validation.extract_all_words board in
  assert_equal ~printer:string_of_int 0 (List.length words);
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'W' in
  let tile1 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 4) 'H' in
  let tile2 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 3) 'A' in
  let tile3 = Banana_gram.Tile.create (Lib.Tile.Position.create 5 2) 'T' in
  let tile4 = Banana_gram.Tile.create (Lib.Tile.Position.create 4 2) 'C' in
  let tile5 = Banana_gram.Tile.create (Lib.Tile.Position.create 3 2) 'T' in
  let board = Banana_gram.Board.set tile board in
  let words = Validation.extract_all_words board in
  assert_equal ~printer:string_of_int 0 (List.length words);
  let board = Banana_gram.Board.set tile1 board in
  let board = Banana_gram.Board.set tile2 board in
  let board = Banana_gram.Board.set tile3 board in
  let words = Validation.extract_all_words board in
  assert_equal ~printer:string_of_int 1 (List.length words);
  let board = Banana_gram.Board.set tile4 board in
  let board = Banana_gram.Board.set tile5 board in
  let words = Validation.extract_all_words board in
  assert_equal ~printer:string_of_int 2 (List.length words);
  assert_bool "crossing words should be connected" (Validation.is_connected board)


let test_is_connected_empty_board _ =
  let board = Banana_gram.Board.empty in
  assert_bool "empty board should be connected" (Validation.is_connected board)


let create_board_from_list tile_specs =
  List.fold tile_specs ~init:Banana_gram.Board.empty ~f:(fun board (row, col, char) ->
    let tile = Banana_gram.Tile.create (Lib.Tile.Position.create row col) char in
    Banana_gram.Board.set tile board
  )

let create_test_dict words =
  let test_file = Stdlib.Filename.temp_file "test_dict" ".txt" in
  let oc = Out_channel.create test_file in
  List.iter words ~f:(fun word ->
    Out_channel.output_string oc (word ^ "\n")
  );
  Out_channel.close oc;
  match Dictionary.load test_file with
  | Ok dict ->
      Stdlib.Sys.remove test_file;
      dict
  | Error msg ->
      Stdlib.Sys.remove test_file;
      failwith ("Failed to create test dictionary: " ^ msg)

let test_dictionary_load_success _ =
  let test_file = "test_dict.txt" in
  let oc = Out_channel.create test_file in
  Out_channel.output_string oc "CAT\nDOG\nBIRD\n";
  Out_channel.close oc;
  
  match Dictionary.load test_file with
  | Ok dict ->
      assert_bool "should contain CAT" (Dictionary.contains dict "CAT");
      assert_bool "should contain cat (case insensitive)" 
        (Dictionary.contains dict "cat");
        Stdlib.Sys.remove test_file 
  | Error _ ->
      Stdlib.Sys.remove test_file; 
      assert_failure "Dictionary load should succeed"

let test_validate_valid_word _ =
  let board = create_board_from_list [(5, 5, 'C'); (6, 5, 'A'); (7, 5, 'T')] in
  let dict = create_test_dict ["CAT"; "DOG"] in
  match Validation.validate board dict with
  | Ok () -> ()
  | Error _ -> assert_failure "Should accept valid word"

let test_validate_invalid_word _ =
  let board = create_board_from_list [(5, 5, 'X'); (6, 5, 'Y'); (7, 5, 'Z')] in
  let dict = create_test_dict ["CAT"; "DOG"] in
  match Validation.validate board dict with
  | Error invalid ->
      assert_bool "should contain XYZ" 
        (List.exists invalid ~f:(fun word -> String.equal word "XYZ"))
  | Ok () -> assert_failure "Should reject invalid word"

(*Solver tests*)
let test_solver_utils _ =
  let test_dict = "hint_test_dict.txt" in
  let oc_dict = Out_channel.create test_dict in
  Out_channel.output_string oc_dict "WHAT\nTOT\nOAT\nTOW\nTWO\nTO\nOH\nOW\n";
  Out_channel.close oc_dict;

  let test_dist = "hint_test_dist.txt" in
  let oc_dist = Out_channel.create test_dist in
  (* word distribution *)
  Out_channel.output_string oc_dist "13\n3\n3\n6\n18\n3\n4\n3\n12\n2\n2\n5\n3\n8\n11\n3\n2\n9\n6\n9\n6\n3\n3\n2\n3\n2\n";
  Out_channel.close oc_dist;

  let utils_str = Solver.set_up_utils test_dict test_dist
  |> Solver.utils_as_str in

  assert_bool "Utils not generated properly." (String.is_substring utils_str ~substring:"ANAGRAMS MAP") 

let test_solver_hint _ =
  let test_dict = "hint_test_dict.txt" in
  let oc_dict = Out_channel.create test_dict in
  Out_channel.output_string oc_dict "WHAT\nTOT\nOAT\nTOW\nTWO\nTO\nOH\nOW\n";
  Out_channel.close oc_dict;

  let test_dist = "hint_test_dist.txt" in
  let oc_dist = Out_channel.create test_dist in
  Out_channel.output_string oc_dist "13\n3\n3\n6\n18\n3\n4\n3\n12\n2\n2\n5\n3\n8\n11\n3\n2\n9\n6\n9\n6\n3\n3\n2\n3\n2\n";
  Out_channel.close oc_dist;

  let utils = Solver.set_up_utils test_dict test_dist in

  let board = Banana_gram.Board.empty in
  let tile_w = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'W' in
  let tile_h = Banana_gram.Tile.create (Lib.Tile.Position.create 5 4) 'H' in
  let tile_a = Banana_gram.Tile.create (Lib.Tile.Position.create 5 3) 'A' in
  let tile_t = Banana_gram.Tile.create (Lib.Tile.Position.create 5 2) 'T' in
  let board = Banana_gram.Board.set tile_w board in
  let board = Banana_gram.Board.set tile_h board in
  let board = Banana_gram.Board.set tile_a board in
  let board = Banana_gram.Board.set tile_t board in

  let rack = [ 'T'; 'O'; ] in

  let hint = Solver.calculate_hint utils rack board in
  let hint_msg =
    match hint with
    | None -> assert_failure "Solver didn't find hint"
    | Some h -> Solver.hint_as_string h in

  assert_bool "Solver found invalid hint." (String.is_substring hint_msg ~substring:"going across") 

let test_solver_hint_prefer_longer_words _ =
  let test_dict = "hint_test_dict.txt" in
  let oc_dict = Out_channel.create test_dict in
  Out_channel.output_string oc_dict "WHAT\nOW\nHOT\n";
  Out_channel.close oc_dict;

  let test_dist = "hint_test_dist.txt" in
  let oc_dist = Out_channel.create test_dist in
  Out_channel.output_string oc_dist "13\n3\n3\n6\n18\n3\n4\n3\n12\n2\n2\n5\n3\n8\n11\n3\n2\n9\n6\n9\n6\n3\n3\n2\n3\n2\n";
  Out_channel.close oc_dist;

  let utils = Solver.set_up_utils test_dict test_dist in

  let board = Banana_gram.Board.empty in
  let tile_w = Banana_gram.Tile.create (Lib.Tile.Position.create 5 5) 'W' in
  let tile_h = Banana_gram.Tile.create (Lib.Tile.Position.create 5 4) 'H' in
  let tile_a = Banana_gram.Tile.create (Lib.Tile.Position.create 5 3) 'A' in
  let tile_t = Banana_gram.Tile.create (Lib.Tile.Position.create 5 2) 'T' in
  let board = Banana_gram.Board.set tile_w board in
  let board = Banana_gram.Board.set tile_h board in
  let board = Banana_gram.Board.set tile_a board in
  let board = Banana_gram.Board.set tile_t board in

  let rack = [ 'T'; 'O'; ] in

  let hint = Solver.calculate_hint utils rack board in
  let hint_msg =
    match hint with
    | None -> assert_failure "Solver didn't find hint"
    | Some h -> Solver.hint_as_string h in

  assert_equal "You should play HOT going across at (5,4)" hint_msg

(*Bananagram tests*)
let test_place_word_on_board _ =
  let board = Banana_gram.Board.empty in
  let pos = Lib.Tile.Position.create 0 0 in
  let word = Banana_gram.Word.create pos ['F'; 'U'; 'N'] in
  let board' = Banana_gram.place_word_on_board word board in
  
  assert_equal 3 (Banana_gram.Board.size board');
  assert_equal (Some 'F') (Banana_gram.get_letter_at pos board');
  assert_equal (Some 'U') (Banana_gram.get_letter_at (Lib.Tile.Position.create 0 1) board');
  assert_equal (Some 'N') (Banana_gram.get_letter_at (Lib.Tile.Position.create 0 2) board')

(* Test Banana_gram.ml helper functions *)
let test_create_tile _ =
  let pos = Lib.Tile.Position.create 2 3 in
  let tile = Banana_gram.create_tile pos 'Q' in
  
  (* Check position *)
  assert_equal 2 (Lib.Tile.Position.row (Banana_gram.Tile.position tile));
  assert_equal 3 (Lib.Tile.Position.col (Banana_gram.Tile.position tile));
  
  (* Check value *)
  assert_equal 'Q' (Banana_gram.Tile.value tile)

let test_create_word _ =
  let start = Lib.Tile.Position.create 0 0 in
  let letters = ['T'; 'E'; 'S'; 'T'] in
  let word = Banana_gram.create_word start letters in
  
  (* Check length *)
  assert_equal 4 (Banana_gram.Word.length word);
  
  (* Check values *)
  assert_equal letters (Banana_gram.Word.values word);
  
  (* Check string representation *)
  assert_equal "TEST" (Banana_gram.word_to_string word);
  
  (* Check start position *)
  let word_start = Banana_gram.Word.start word in
  assert_equal 0 (Lib.Tile.Position.row word_start);
  assert_equal 0 (Lib.Tile.Position.col word_start)

let test_empty_board _ =
  let board = Banana_gram.empty_board () in
  
  (* Should be empty *)
  assert_bool "board should be empty" (Banana_gram.Board.is_empty board);
  
  (* Should have size 0 *)
  assert_equal 0 (Banana_gram.Board.size board);
  
  (* Getting any position should return None *)
  assert_equal None (Banana_gram.Board.get (Lib.Tile.Position.create 0 0) board)


(* Test Suite *)
let position_tests = "Position tests" >::: [
  "create" >:: test_position_create;
  "up" >:: test_position_up;
  "down" >:: test_position_down;
  "right" >:: test_position_right;
  "left" >:: test_position_left;
]

let tile_tests = "Tile tests" >::: [
  "create" >:: test_tile_create;
  "to_string">:: test_tile_to_string
]

let word_tests = "Word tests" >::: [
  "create" >:: test_word_create;
  "start" >:: test_word_start;
  "to_string" >:: test_word_to_string;
  "empty_false" >:: test_word_is_empty_false;
  "empty_true" >:: test_word_is_empty_true
]

let board_tests = "Board tests" >::: [
  "empty" >:: test_board_empty;
  "set and get" >:: test_board_set_get;
  "mem" >:: test_board_mem;
  "of_tiles success" >:: test_board_of_tiles_success;
  "of_tiles duplicate error" >:: test_board_of_tiles_duplicate_error;
  "of_tiles empty" >:: test_board_of_tiles_empty;
  "to_tiles" >:: test_board_to_tiles;
  "to_tiles empty" >:: test_board_to_tiles_empty;
  "remove" >:: test_board_remove;
  "remove nonexistent" >:: test_board_remove_nonexistent;
  "roundtrip to_tiles/of_tiles" >:: test_board_roundtrip;
]

let validation_tests = "Validation tests" >::: [
  "word horizontal" >:: test_valid_horizontal;
  "word vertical" >:: test_valid_vertical;
  "validation extract all" >:: test_valid_extract_all;
  "connected empty board" >:: test_is_connected_empty_board;
  "dictionary load" >:: test_dictionary_load_success;
  "validate valid" >:: test_validate_valid_word;
  "validate invalid" >:: test_validate_invalid_word;
]

let solver_tests = "Solver tests" >::: [
  "hint utils" >:: test_solver_utils;
  "hint base message" >:: test_solver_hint;
  "hint prefer long" >:: test_solver_hint_prefer_longer_words;
]

let bananagram_tests = "Bananagram tests" >::: [
  "place word on board" >:: test_place_word_on_board;
  "test create word " >:: test_create_word;
  "create tile" >:: test_create_tile;
  "empty board" >:: test_empty_board
]

let series = "All tests" >::: [
  position_tests;
  tile_tests;
  word_tests;
  board_tests;
  validation_tests;
  solver_tests;
  bananagram_tests;
]

let () = run_test_tt_main series
