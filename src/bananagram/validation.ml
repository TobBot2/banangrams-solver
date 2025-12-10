open Core

let is_word_start_horizontal pos board =
  let down = Lib.Tile.Position.down pos in
  let up = Lib.Tile.Position.up pos in
  
  Banana_gram.Board.mem pos board
  && not (Banana_gram.Board.mem down board)
  && Banana_gram.Board.mem up board

let is_word_start_vertical_down pos board =
  let right = Lib.Tile.Position.right pos in
  let left = Lib.Tile.Position.left pos in
  
  Banana_gram.Board.mem pos board
  && not (Banana_gram.Board.mem right board)
  && Banana_gram.Board.mem left board

let extract_word_horizontal pos board =
  if not (is_word_start_horizontal pos board) then
    None
  else
    let rec collect_tiles current_pos acc =
      match Banana_gram.Board.get current_pos board with
      | None -> List.rev acc
      | Some value ->
          let tile = Banana_gram.Tile.create current_pos value in
          let next_pos = Lib.Tile.Position.up current_pos in
          collect_tiles next_pos (tile :: acc)
    in
    let tiles = collect_tiles pos [] in
    if List.length tiles >= 2 then
      Some tiles
    else
      None

let extract_word_vertical_down pos board =
  if not (is_word_start_vertical_down pos board) then
    None
  else
    let rec collect_tiles current_pos acc =
      match Banana_gram.Board.get current_pos board with
      | None -> List.rev acc
      | Some value ->
          let tile = Banana_gram.Tile.create current_pos value in
          let next_pos = Lib.Tile.Position.left current_pos in
          collect_tiles next_pos (tile :: acc)
    in
    let tiles = collect_tiles pos [] in
    if List.length tiles >= 2 then
      Some tiles
    else
      None

let extract_all_words board =
  let all_positions = Banana_gram.Board.positions board in
  
  let horizontal_words =
    List.filter_map all_positions ~f:(fun pos ->
      extract_word_horizontal pos board
    )
  in
  
  let vertical_words =
    List.filter_map all_positions ~f:(fun pos ->
      extract_word_vertical_down pos board
    )
  in
  horizontal_words @ vertical_words

let connected_positions start board =
  let rec dfs visited pos =
    if Set.mem visited pos then
      visited
    else if not (Banana_gram.Board.mem pos board) then
      visited
    else
      let visited = Set.add visited pos in
      let neighbors = [
        Lib.Tile.Position.up pos;
        Lib.Tile.Position.down pos;
        Lib.Tile.Position.left pos;
        Lib.Tile.Position.right pos;
      ] in
      List.fold neighbors ~init:visited ~f:dfs
  in
  
  dfs (Set.empty (module Lib.Tile.Position)) start

let is_connected board =
  if Banana_gram.Board.is_empty board then
    true
  else
    let all_positions = Banana_gram.Board.positions board in
    match all_positions with
    | [] -> true
    | start :: _ ->
        let reachable = connected_positions start board in
        let all_positions_set = 
          Set.of_list (module Lib.Tile.Position) all_positions 
        in
        Set.equal reachable all_positions_set

let find_invalid_words board dict =
  let words = extract_all_words board in
  List.filter_map words ~f:(fun word ->
    let word_str = Banana_gram.Word.to_string word in
    if Dictionary.contains dict word_str then
      None
    else
      Some word_str
  )

let validate board dict =
  if not (is_connected board) then
    Error ["Board is not connected"]
  else
    let invalid = find_invalid_words board dict in
    if List.is_empty invalid then
      Ok ()
    else
      Error invalid