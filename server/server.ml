open Core
open Lib
open Bananagram
(*open Lib.Solver*)
(*open Dream*)

  (*when tile dragged from rack in frontend, remove from rack in backend*)
  (*initial tiles are a random selection from the bag - peek_random_tiles_from_bag*)
 (* tile bag: make a list of potential tiles *)

(*getting the letters from the file: should we move this to a utils in lib?*)

(*UTILS ONCE LIB COMPILING*)
let read_letter_list filename =
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

(*need to add an error for the file not found*)
let tile_bag = read_letter_list "banana-dist.txt"

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

(*temporarily moving peek b/c lib dune is not building right now.*)
(** [peek_random_tiles_from_bag tile_bag count] returns [count] tiles from [tile_bag] *)
let peek_random_tiles_from_bag tile_bag count =
  (* generate random indices to pull from *)
  let rand_indices = List.init count ~f:(fun _ -> Random.int (List.length tile_bag)) in
  (* loop through tiles, accumulating if index matches a randomly generated one *)
  List.foldi tile_bag ~init:[] ~f:(fun i acc tile ->
    if List.exists rand_indices ~f:(fun idx -> idx = i) then tile :: acc
    else acc
  )

let get_random_tiles : Dream.route =
  Dream.get "/get_random_tiles" (fun request ->
      let count = 
        match Dream.query request "count" with
        | Some s -> (try int_of_string s with _ -> 21)
        | None -> 21
      in
      
      (*let tiles = Lib.Solver.peek_random_tiles_from_bag tile_bag count in*)
      let tiles = peek_random_tiles_from_bag tile_bag count in
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
      
      (*let word = Lib.Solver.get_the_word*)
      let word = "hello" in
      
      (*returning a string for now: will return a character array later!*)
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

(** Validation helper functions *)

(** Validate board structure (connectivity, duplicates) *)
let validate_board_structure (board : Board.t) 
    : (unit, string) result =
  if Lib.Board.is_empty board then
    Error "Board is empty"
  else if not (Validation.is_connected board) then
    Error "Board tiles must be connected"
  else
    Ok ()

(** Validate words against dictionary *)
let validate_words (board : Lib.Board.t) (dict : Validation.Dictionary.t) 
    : (int, string list) result =
  let words = Validation.extract_all_words board in
  Printf.printf "Found %d words: " (List.length words);
  List.iter words ~f:(fun word ->
    Printf.printf "%s " (Word.to_string word)
  );
  Printf.printf "\n%!";
  
  match Validation.validate board dict with
  | Ok () -> Ok (List.length words)
  | Error invalid_words -> Error invalid_words

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
                    Some (Tile.create (Tile.Position.create row col) (String.get letter 0))
                  with _ -> None)
              | _ -> None)
          in
          
          (* Create board from tiles *)
          (match Lib.Board.of_tiles tiles with
          | Error err ->
              Printf.printf "Board creation failed: %s\n%!" err;
              Dream.json ~status:`Bad_Request 
                (sprintf "\"Error: %s\"" err)
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          
          | Ok board ->
              let num_tiles = Banana_gram.size board in
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
                          Printf.printf "✓ All words valid\n%!";
                          Dream.json ~status:`OK 
                            (sprintf "\"Valid! %d tiles, %d words\"" 
                              num_tiles num_words)
                            ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                      
                      | Error invalid_words ->
                          Printf.printf "✗ Invalid words: %s\n%!" 
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


(*let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/**" (Dream.static "../client/dist"); (*May only work in dev mode?*)
  ]*)

(*working with a monad and mutation here: is that okay?*)


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








(*open Chess_ai

let check_valid_board (board : string option) : bool =
  match board with
  | None -> false
  | Some board -> (
      match Board.Board_state.import board with Some _ -> true | None -> false)

let str_opt_to_char (str_opt : string option) : char option =
  match str_opt with
  | None -> None
  | Some str -> (
      match String.to_list str with
      | ch :: _ -> Some (Char.uppercase ch)
      | [] -> None)

let decode_uri_opt (str_opt : string option) : string option =
  match str_opt with None -> None | Some str -> Some (Uri.pct_decode str)

let check_difficulty (str_opt : string option) : int option =
  match str_opt with
  | None -> None
  | Some str -> (
      match int_of_string_opt str with
      | Some difficulty ->
          if difficulty >= 1 && difficulty <= 3 then Some difficulty else None
      | None -> None)

let generate_response (board : string option) (color : string option)
    (difficulty : string option) : Dream.response Lwt.t =
  match
    (decode_uri_opt board, str_opt_to_char color, check_difficulty difficulty)
  with
  | Some board, Some color, Some difficulty ->
      Dream.json ~status:`OK
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        (Minimax.generate_next_move board color difficulty)
  | Some _, Some _, None ->
      Dream.json ~status:`Bad_Request
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        "Invalid difficulty"
  | Some _, None, _ ->
      Dream.json ~status:`Bad_Request
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        "Invalid color"
  | None, _, _ ->
      Dream.json ~status:`Bad_Request
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
        "Invalid board"

let get_suggested_move : Dream.route =
  Dream.get "/get_suggested_move" (fun request ->
      let board = Dream.query request "board" in
      let color = Dream.query request "color" in
      let difficulty = Dream.query request "difficulty" in
      if check_valid_board board then generate_response board color difficulty
      else
        Dream.json ~status:`Bad_Request
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          "Invalid board")

let is_valid_board : Dream.route =
  Dream.get "/is_valid_board" (fun request ->
      let board = Dream.query request "board" in
      if check_valid_board board then
        Dream.json ~status:`OK
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          "Valid board"
      else
        Dream.json ~status:`Bad_Request
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          "Invalid board")
*)
(*
let () =
  Dream.run @@ Dream.logger 
  @@ Dream.memory_sessions
  @@ Dream.router [ get_suggested_move; is_valid_board ]
*)

(*let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.from_file "client/dist/index.html");
    Dream.get "/assets/**" (Dream.static "client/dist/assets");
  ]*)

