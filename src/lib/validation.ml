open Core

module Dictionary = struct
  type t = String.Set.t
  
  let load filepath =
    try
      let words = In_channel.read_lines filepath in
      let dict = 
        List.fold words ~init:String.Set.empty ~f:(fun acc word ->
          let normalized = String.lowercase (String.strip word) in
          if String.is_empty normalized then acc
          else Set.add acc normalized)
      in
      Ok dict
    with
    | Sys_error msg -> Error (sprintf "Failed to load dictionary: %s" msg)
    | e -> Error (sprintf "Error loading dictionary: %s" (Exn.to_string e))
  
  let contains dict word =
    Set.mem dict (String.lowercase word)

end

let is_word_start_horizontal pos board =
  Board.mem pos board &&
  Board.mem (Tile.Position.right pos) board &&
  not (Board.mem (Tile.Position.left pos) board)

let is_word_start_vertical pos board =
  Board.mem pos board &&
  Board.mem (Tile.Position.down pos) board &&
  not (Board.mem (Tile.Position.up pos) board)

let extract_word_horizontal pos board =
  if not (is_word_start_horizontal pos board) then None
  else
    let rec collect_tiles current_pos acc =
      match Board.get_tile current_pos board with
      | None -> List.rev acc
      | Some tile ->
          let next_pos = Tile.Position.right current_pos in
          collect_tiles next_pos (tile :: acc)
    in
    let tiles = collect_tiles pos [] in
    if List.length tiles >= 2 then
      Some (Word.of_tiles tiles)
    else
      None

let extract_word_vertical pos board =
  if not (is_word_start_vertical pos board) then None
  else
    let rec collect_tiles current_pos acc =
      match Board.get_tile current_pos board with
      | None -> List.rev acc
      | Some tile ->
          let next_pos = Tile.Position.down current_pos in
          collect_tiles next_pos (tile :: acc)
    in
    let tiles = collect_tiles pos [] in
    if List.length tiles >= 2 then
      Some (Word.of_tiles tiles)
    else
      None

let extract_all_words board =
  if Board.is_empty board then []
  else
    let positions = Board.positions board in
    let extract_from_position pos =
      let horizontal = extract_word_horizontal pos board in
      let vertical = extract_word_vertical pos board in
      List.filter_opt [horizontal; vertical]
    in
    List.concat_map positions ~f:extract_from_position

let get_adjacent_positions pos board =
  let candidates = [
    Tile.Position.up pos;
    Tile.Position.down pos;
    Tile.Position.right pos;
    Tile.Position.left pos;
  ] in
  List.filter candidates ~f:(fun p -> Board.mem p board)

let connected_positions start board =
  if not (Board.mem start board) then
    Tile.Position.Set.empty
  else
    let rec dfs current visited =
      if Set.mem visited current then visited
      else
        let visited' = Set.add visited current in
        let neighbors = get_adjacent_positions current board in
        List.fold neighbors ~init:visited' ~f:(fun acc neighbor ->
          dfs neighbor acc)
    in
    dfs start Tile.Position.Set.empty

let is_connected board =
  if Board.is_empty board then true
  else
    let all_positions = Board.positions board in
    match all_positions with
    | [] -> true
    | start :: _ ->
        let reachable = connected_positions start board in
        Set.length reachable = Board.size board

let find_invalid_words board dict =
  let words = extract_all_words board in
  List.filter_map words ~f:(fun word ->
    let word_str = Word.to_string word in
    if Dictionary.contains dict word_str then None
    else Some word_str)

let validate board dict =
  if Board.is_empty board then Ok ()
  else if not (is_connected board) then
    Error ["Board is not connected - all tiles must form a single group"]
  else
    let invalid = find_invalid_words board dict in
    if List.is_empty invalid then Ok ()
    else Error invalid