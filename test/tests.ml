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

let series = "All tests" >::: [
  position_tests;
  tile_tests;
  word_tests;
  board_tests;
]

let () = run_test_tt_main series
