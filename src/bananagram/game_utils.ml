open Core

let read_letter_list filename : char list =
  let ic = In_channel.create filename in
  let rec read_lines acc =
    match In_channel.input_line ic with
    | Some line ->
        let parts = String.split_on_chars line ~on:['#'] in
        (match parts with
        | count_str :: letter_str :: _ ->
            let count = int_of_string (String.strip count_str) in
            let letter = String.strip letter_str |> fun s -> s.[0] in
            let letters = List.init count ~f:(fun _ -> letter) in
            read_lines (letters @ acc)
        | _ -> read_lines acc)
    | None ->
        In_channel.close ic;
        List.rev acc
  in
  read_lines []

let peek_random_tiles_from_bag (tile_bag : char list) (count : int) : char list * char list =
  let bag_size = List.length tile_bag in
  let actual_count = Int.min count bag_size in
  if actual_count = 0 then ([], tile_bag)
  else
    let shuffled = List.permute ~random_state:(Random.State.make_self_init ()) tile_bag in
    let result, remaining = List.split_n shuffled actual_count in
    (result, remaining)
