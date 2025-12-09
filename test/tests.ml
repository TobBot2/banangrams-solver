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
  assert_equal 5 (Lib.Tile.Position.row up_pos);  
  assert_equal 11 (Lib.Tile.Position.col up_pos)

let test_position_down _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let down_pos = Lib.Tile.Position.down pos in
  assert_equal 5 (Lib.Tile.Position.row down_pos); 
  assert_equal 9 (Lib.Tile.Position.col down_pos)

let test_position_right _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let right_pos = Lib.Tile.Position.right pos in
  assert_equal 6 (Lib.Tile.Position.row right_pos);
  assert_equal 10 (Lib.Tile.Position.col right_pos)

let test_position_left _ =
  let pos = Lib.Tile.Position.create 5 10 in
  let left_pos = Lib.Tile.Position.left pos in
  assert_equal 4 (Lib.Tile.Position.row left_pos);
  assert_equal 10 (Lib.Tile.Position.col left_pos)  

(* Tile tests - use Banana_gram.Tile (the instantiated version) *)
let test_tile_create _ =
  let tile = Banana_gram.Tile.create (Lib.Tile.Position.create 3 4) 'A' in
  assert_equal 3 (Lib.Tile.Position.row (Banana_gram.Tile.position tile));
  assert_equal 4 (Lib.Tile.Position.col (Banana_gram.Tile.position tile));
  assert_equal 'A' (Banana_gram.Tile.value tile)

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

(* Board tests *)
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
  match Validation.Dictionary.load test_file with
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
  
  match Validation.Dictionary.load test_file with
  | Ok dict ->
      assert_bool "should contain CAT" (Validation.Dictionary.contains dict "CAT");
      assert_bool "should contain cat (case insensitive)" 
        (Validation.Dictionary.contains dict "cat");
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
]

let word_tests = "Word tests" >::: [
  "create" >:: test_word_create;
  "start" >:: test_word_start;
  "to_string" >:: test_word_to_string;
]

let board_tests = "Board tests" >::: [
  "empty" >:: test_board_empty;
  "set and get" >:: test_board_set_get;
  "mem" >:: test_board_mem;
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

let bananagram_tests = "Bananagram tests" >::: [
  "place word on board" >:: test_place_word_on_board;
]

let series = "All tests" >::: [
  position_tests;
  tile_tests;
  word_tests;
  board_tests;
  validation_tests;
  bananagram_tests;
]

let () = run_test_tt_main series
