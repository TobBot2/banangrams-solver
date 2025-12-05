open Core 
open OUnit2
open Lib

(* Helper to create tiles easily for testing *)
(** let make_tile row col char =
  Tile.create (Tile.Position.create row col) char

let test_position_create _ =
  let pos = Tile.Position.create 5 10 in
  assert_equal 5 (Tile.Position.row pos);
  assert_equal 10 (Tile.Position.col pos)

let test_position_up _ =
  let pos = Tile.Position.create 5 10 in
  let up_pos = Tile.Position.up pos in
  assert_equal 5 (Tile.Position.row up_pos);
  assert_equal 11 (Tile.Position.col up_pos)

let test_position_down _ =
  let pos = Tile.Position.create 5 10 in
  let down_pos = Tile.Position.down pos in
  assert_equal 5 (Tile.Position.row down_pos);
  assert_equal 9 (Tile.Position.col down_pos)

let test_position_right _ =
  let pos = Tile.Position.create 5 10 in
  let right_pos = Tile.Position.right pos in
  assert_equal 6 (Tile.Position.row right_pos);
  assert_equal 10 (Tile.Position.col right_pos)

let test_position_left _ =
  let pos = Tile.Position.create 5 10 in
  let left_pos = Tile.Position.left pos in
  assert_equal 4 (Tile.Position.row left_pos);
  assert_equal 10 (Tile.Position.col left_pos)

(* Test Tile *)
let test_tile_create _ =
  let tile = make_tile 3 4 'A' in
  assert_equal 3 (Tile.Position.row (Tile.position tile));
  assert_equal 4 (Tile.Position.col (Tile.position tile));
  assert_equal 'A' (Tile.value tile)

(* Test Word *)
let test_word_create _ =
  let start_pos = Tile.Position.create 0 0 in
  let word = Word.create start_pos ['H'; 'I'] in
  assert_equal 2 (Word.length word);
  assert_equal ['H'; 'I'] (Word.chars word);
  assert_equal "HI" (Word.to_string word)

let test_word_start _ =
  let start_pos = Tile.Position.create 5 10 in
  let word = Word.create start_pos ['C'; 'A'; 'T'] in
  let word_start = Word.start word in
  assert_equal 5 (Tile.Position.row word_start);
  assert_equal 10 (Tile.Position.col word_start)

let test_word_to_string _ =
  let word = Word.create (Tile.Position.create 0 0) ['D'; 'O'; 'G'] in
  assert_equal "DOG" (Word.to_string word)


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

let series = "All tests" >::: [
  position_tests;
  tile_tests;
  word_tests;]

let () = run_test_tt_main series *)