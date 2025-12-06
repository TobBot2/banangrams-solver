open Core
open Lib
open Bananagram

(*WILL BE MOVED TO UTILS: haven't moved yet because want to integrate solver first*)
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
        Printf.printf "Returning %d tiles in dict\n%!" (List.length acc);
        List.rev acc
  in
  read_lines []

(* Dictionary reference - loaded at startup *)
let dictionary_ref : Validation.Dictionary.t option ref = ref None
(* Load dictionary from file *)
let load_dictionary filepath =
  match Validation.Dictionary.load filepath with
  | Ok dict -> 
      dictionary_ref := Some dict;
      Printf.printf "Dictionary loaded from %s\n%!" filepath
  | Error err ->
      Printf.printf "Failed to load dictionary: %s\n%!" err

(** [peek_random_tiles_from_bag tile_bag count] returns [count] tiles from [tile_bag] *)
let peek_random_tiles_from_bag tile_bag count =
  let bag_size = List.length tile_bag in
  let actual_count = Int.min count bag_size in
  
  if actual_count = 0 then []
  else
    let shuffled = List.permute ~random_state:(Random.State.make_self_init ()) tile_bag in
    (*let result = List.take shuffled actual_count in*)
    let result = List.sub shuffled ~pos:0 ~len:actual_count in
    Printf.printf "Returning %d tiles\n%!" (List.length result);
    result


(** Validation helper functions *)

(** Validate board structure (connectivity, duplicates) *)
let validate_board_structure (board : Banana_gram.Board.t) 
    : (unit, string) result =
  if Banana_gram.Board.is_empty board then
    Error "Board is empty"
  else if not (Validation.is_connected board) then
    Error "Board tiles must be connected"
  else
    Ok ()

(** Validate words against dictionary *)
let validate_words (board : Banana_gram.Board.t) (dict : Validation.Dictionary.t) 
    : (int, string list) result =
  let words = Validation.extract_all_words board in
  Printf.printf "Found %d words: " (List.length words);
  List.iter words ~f:(fun word ->
    Printf.printf "%s " (Banana_gram.Word.to_string word)
  );
  Printf.printf "\n%!";
  
  match Validation.validate board dict with
  | Ok () -> Ok (List.length words)
  | Error invalid_words -> Error invalid_words
(*END UTILS*)

(*using mutation for the tile_bag because two players must access it, and it
is initialized once on server startup*)
let initial_tile_bag : char list = read_letter_list "banana-dist.txt"
let tile_bag_ref = ref initial_tile_bag
let tile_bag_mutex = Lwt_mutex.create ()

let get_random_tiles : Dream.route =
  Dream.get "/get_random_tiles" (fun request ->
      let count = 
        match Dream.query request "count" with
        | Some s -> (try int_of_string s with _ -> 21)
        | None -> 21
      
    in
      (* Lock the mutex to prevent race conditions when multiple players request tiles *)
      let%lwt tiles = Lwt_mutex.with_lock tile_bag_mutex (fun () ->
        let tiles = peek_random_tiles_from_bag !tile_bag_ref count in
        tile_bag_ref := List.filter !tile_bag_ref ~f:(fun tile -> 
          not (List.mem tiles tile ~equal:Char.equal)
        );
        Lwt.return tiles
      ) in
      let tiles_json = 
        tiles 
        |> List.map ~f:(fun c -> `String (String.make 1 c))
        |> fun lst -> `List lst
        |> Yojson.Basic.to_string
      in
      
      Dream.json ~status:`OK
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        tiles_json
  )

let hint : Dream.route =
  Dream.get "/hint" (fun _ ->
      let word = "hello" in
      
      (*returning a string for now: will return a character array from solver*)
       let hint_json = `String word |> Yojson.Basic.to_string in
      Dream.json ~status:`OK
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        hint_json

      (*let hint_json = 
        word
        |> List.map ~f:(fun c -> `String (String.make 1 c))
        |> fun lst -> `List lst
        |> Yojson.Basic.to_string
      in*)

  )

let validate : Dream.route =
  Dream.post "/validate" (fun request ->
    let%lwt body = Dream.body request in
    Printf.printf "Body: %s\n%!" body;
    try
      match Yojson.Basic.from_string body with 
      | `Assoc pairs ->
          (* Parse tiles directly from JSON *)
          Printf.printf "Parsed %d pairs\n%!" (List.length pairs);
          let tiles =
            List.filter_map pairs ~f:(fun (coord, json) ->
              match json, String.split coord ~on:',' with
              | `String letter, [col_str; row_str] when String.length letter = 1 ->
                  (try
                    let col = Int.of_string (String.strip row_str) in
                    let row = Int.of_string (String.strip col_str) in
                    Printf.printf "  -> (%d,%d) = '%s'\n%!" row col letter;
                    Some (Banana_gram.Tile.create (Tile.Position.create row col) (String.get letter 0))
                  with _ -> None)
              | _ -> None)
          in
          
          (match Banana_gram.Board.of_tiles tiles with
          | Error err ->
              Printf.printf "Board creation failed: %s\n%!" err;
              Dream.json ~status:`Bad_Request 
                (sprintf "\"Error: %s\"" err)
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          
          | Ok board ->
              let num_tiles = Banana_gram.Board.size board in
              Printf.printf "Board created with %d tiles\n%!" num_tiles;
              
              (* Validate board structure *)
              (match validate_board_structure board with
              | Error err ->
                  Printf.printf "Board structure invalid: %s\n%!" err;
                  Dream.json ~status:`Bad_Request 
                    (sprintf "\"%s\"" err)
                    ~headers:[ ("Access-Control-Allow-Origin", "*") ]
              
              | Ok () ->
                  (* After that Validate words against dictionary *)
                  (match !dictionary_ref with
                  | None ->
                      Printf.printf "No dictionary - structure check only\n%!";
                      let num_words = List.length (Validation.extract_all_words board) in
                      Dream.json ~status:`OK 
                        (sprintf "\"Valid structure: %d tiles, %d words\"" 
                          num_tiles num_words)
                        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                  
                  | Some dict ->
                      Printf.printf "Validating words...\n%!";
                      (match validate_words board dict with
                      | Ok num_words ->
                          Printf.printf "All words valid\n%!";
                          Dream.json ~status:`OK 
                            (sprintf "\"Valid! %d tiles, %d words\"" 
                              num_tiles num_words)
                            ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                      
                      | Error invalid_words ->
                          Printf.printf "Invalid words: %s\n%!" 
                            (String.concat ~sep:", " invalid_words);
                          Dream.json ~status:`Bad_Request 
                            (sprintf "\"Invalid words: %s\"" 
                              (String.concat ~sep:", " invalid_words))
                            ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                      )
                  ))
          )
          
      | _ ->
          Dream.json ~status:`Bad_Request "\"Expected object\""
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    with _ ->
        Dream.json ~status:`Bad_Request "\"Invalid JSON\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
  )

let cors_preflight : Dream.route =
  Dream.options "/validate" (fun _ ->
    Dream.respond ~status:`OK
      ~headers:[
        ("Access-Control-Allow-Origin", "*");
        ("Access-Control-Allow-Methods", "POST, OPTIONS");
        ("Access-Control-Allow-Headers", "Content-Type");
      ]
      ""
  )

let () =

  load_dictionary "dictionary.txt";

  Dream.run ~port:8080
  @@ Dream.logger
  @@ Dream.router [
       Dream.get "/" (fun _ ->
         Dream.html "Bananagrams server is running!");
       get_random_tiles;
       hint;
       cors_preflight;
       validate;
     ]