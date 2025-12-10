open Core
open Lib
open Bananagram

(* Player state management *)
type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  last_active: float;
}

(* Global game state *)
let players_ref : (string, player_state) Hashtbl.t = Hashtbl.create (module String)
let players_mutex = Lwt_mutex.create ()

(*let read_letter_list filename : char list =
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
  read_lines []*)

let dictionary_ref : Dictionary.t option ref = ref None

let solver_utils_ref : Solver.Utils.t option ref = ref None

(*let load_dictionary filepath dictionary_ref=
  match Validation.Dictionary.load filepath with
  | Ok dict -> 
      dictionary_ref := Some dict;
      Printf.printf "Dictionary loaded from %s\n%!" filepath
  | Error err ->
      Printf.printf "Failed to load dictionary: %s\n%!" err

let load_solver dict_filepath dist_filepath solver_utils_ref=
  solver_utils_ref := Some (Solver.set_up_utils dict_filepath dist_filepath);
  Printf.printf "Solver loaded from \n  dictionary: %s\n  distribution: %s\n%!" dict_filepath dist_filepath*)

let initial_tile_bag : char list = Game_utils.read_letter_list "banana-dist.txt"
let tile_bag_ref = ref initial_tile_bag
let tile_bag_mutex = Lwt_mutex.create ()

(*let peek_random_tiles_from_bag (tile_bag : char list) (count : int) : char list * char list =
  let bag_size = List.length tile_bag in
  let actual_count = Int.min count bag_size in
  if actual_count = 0 then ([], tile_bag)
  else
    let shuffled = List.permute ~random_state:(Random.State.make_self_init ()) tile_bag in
    let result, remaining = List.split_n shuffled actual_count in
   (*let result = List.sub shuffled ~pos:0 ~len:actual_count in*)
    Printf.printf "Returning %d tiles\n%!" (List.length result);
    (result, remaining)*)

(* Generate unique player ID *)
let generate_player_id () =
  let timestamp = 
    Time_ns.now () 
    |> Time_ns.to_span_since_epoch 
    |> Time_ns.Span.to_int_sec
  in
  let random = Random.int 10000 in
  sprintf "player_%d_%d" timestamp random

(* Initialize or get player *)
let get_or_create_player player_id : player_state Lwt.t =
  Lwt_mutex.with_lock players_mutex (fun () ->
    match Hashtbl.find players_ref player_id with
    | Some player ->
        let current_time = 
          Time_ns.now () 
          |> Time_ns.to_span_since_epoch 
          |> Time_ns.Span.to_int_sec
          |> Float.of_int 
        in
        (* Update last active time *)
        let updated = { player with last_active = current_time } in
        Hashtbl.set players_ref ~key:player_id ~data:updated;
        Lwt.return updated
    | None ->
        (* Create new player with initial tiles *)
        let tiles, remaining = Game_utils.peek_random_tiles_from_bag !tile_bag_ref 21 in
        (*tile_bag_ref := List.filter !tile_bag_ref ~f:(fun tile -> 
          not (List.mem tiles tile ~equal:Char.equal)
        );*)
        tile_bag_ref := remaining;
        let current_time = 
          Time_ns.now () 
          |> Time_ns.to_span_since_epoch 
          |> Time_ns.Span.to_int_sec 
          |> Float.of_int
        in
        let new_player = {
          id = player_id;
          tiles = tiles;
          board = [];
          last_active = current_time;
        } in
        Hashtbl.set players_ref ~key:player_id ~data:new_player;
        Printf.printf "Created new player: %s\n%!" player_id;
        let _ = new_player.board in (*dummy to avoid build error*)
        let _ = new_player.last_active in (*dummy to avoid build error*)
        Lwt.return new_player
  )

(* Join game - returns player ID *)
let join_game : Dream.route =
  Dream.post "/join" (fun _ ->
    let player_id = generate_player_id () in
    let%lwt player = get_or_create_player player_id in
    
    let response = `Assoc [
      ("playerId", `String player.id);
      ("tiles", `List (List.map player.tiles ~f:(fun c -> `String (String.make 1 c))));
      ("tilesRemaining", `Int (List.length !tile_bag_ref));
    ] |> Yojson.Basic.to_string in
    
    Dream.json ~status:`OK
      ~headers:[ ("Access-Control-Allow-Origin", "*") ]
      response
  )

(* Get player tiles *)
let get_tiles : Dream.route =
  Dream.get "/get_tiles" (fun request ->
    match Dream.query request "playerId" with
    | None -> Dream.json ~status:`Bad_Request "\"Missing playerId\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    | Some player_id ->
        let%lwt player = get_or_create_player player_id in
        let tiles_json = 
          player.tiles
          |> List.map ~f:(fun c -> `String (String.make 1 c))
          |> fun lst -> `List lst
          |> Yojson.Basic.to_string
        in
        Dream.json ~status:`OK
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          tiles_json
  )

(* Draw more tiles for a specific player *)
let draw_tiles : Dream.route =
  Dream.post "/draw_tiles" (fun request ->
    let%lwt body = Dream.body request in
    try
      match Yojson.Basic.from_string body with
      | `Assoc pairs ->
          let player_id = List.Assoc.find_exn pairs ~equal:String.equal "playerId" 
            |> Yojson.Basic.Util.to_string in
          let count = 
            List.Assoc.find pairs ~equal:String.equal "count"
            |> Option.value_map ~default:3 ~f:Yojson.Basic.Util.to_int in
          
          let%lwt updated_tiles = Lwt_mutex.with_lock tile_bag_mutex (fun () ->
            let%lwt player = get_or_create_player player_id in
            let new_tiles, remaining = Game_utils.peek_random_tiles_from_bag !tile_bag_ref count in
            Printf.printf "Player %s requested %d — returned %d tiles: %s\n%!"
              player_id count (List.length new_tiles) (String.of_char_list new_tiles);
            
              (*tile_bag_ref := List.filter !tile_bag_ref ~f:(fun tile -> 
              not (List.mem new_tiles tile ~equal:Char.equal)*)
              tile_bag_ref := remaining
            ;
            Printf.printf "Tiles left in bag: %d\n%!" (List.length !tile_bag_ref);
            
            
            let all_tiles = player.tiles @ new_tiles in
            let updated_player = { player with tiles = all_tiles } in
            Hashtbl.set players_ref ~key:player_id ~data:updated_player;
            
            Lwt.return all_tiles
          ) in
          
          let response = `Assoc [
            ("tiles", `List (List.map updated_tiles ~f:(fun c -> `String (String.make 1 c))));
            ("tilesRemaining", `Int (List.length !tile_bag_ref));
          ] |> Yojson.Basic.to_string in
          
          Dream.json ~status:`OK
            ~headers:[ ("Access-Control-Allow-Origin", "*") ]
            response
      | _ -> Dream.json ~status:`Bad_Request "\"Invalid request\""
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    with _ ->
      Dream.json ~status:`Bad_Request "\"Invalid JSON\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
  )

(* Validate board for specific player *)
let validate : Dream.route =
  Dream.post "/validate" (fun request ->
    let%lwt body = Dream.body request in
    try
      match Yojson.Basic.from_string body with 
      | `Assoc pairs ->
          (*let player_id = List.Assoc.find_exn pairs ~equal:String.equal "playerId" 
            |> Yojson.Basic.Util.to_string in*)
          let board_data = List.Assoc.find_exn pairs ~equal:String.equal "board" in
          
          let tiles = match board_data with
          | `Assoc board_pairs ->
              List.filter_map board_pairs ~f:(fun (coord, json) ->
                match json, String.split coord ~on:',' with
                | `String letter, [col_str; row_str] when String.length letter = 1 ->
                    (try
                      let col = Int.of_string (String.strip row_str) in
                      let row = Int.of_string (String.strip col_str) in
                      Some (Banana_gram.Tile.create (Tile.Position.create row col) (String.get letter 0))
                    with _ -> None)
                | _ -> None)
          | _ -> []
          in
          
          (match Banana_gram.Board.of_tiles tiles with
          | Error err ->
              Dream.json ~status:`Bad_Request 
                (sprintf "\"Error: %s\"" err)
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          
          | Ok board ->
              if Banana_gram.Board.is_empty board then
                Dream.json ~status:`Bad_Request "\"Board is empty\""
                  ~headers:[ ("Access-Control-Allow-Origin", "*") ]
              else if not (Validation.is_connected board) then
                Dream.json ~status:`Bad_Request "\"Board tiles must be connected\""
                  ~headers:[ ("Access-Control-Allow-Origin", "*") ]
              else
                (match !dictionary_ref with
                | None ->
                    Dream.json ~status:`OK "\"Valid structure\""
                      ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                | Some dict ->
                    (match Validation.validate board dict with
                    | Ok () ->
                        let num_words = List.length (Validation.extract_all_words board) in
                        Dream.json ~status:`OK 
                          (sprintf "\"Valid! %d words\"" num_words)
                          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                    | Error invalid_words ->
                        Dream.json ~status:`Bad_Request 
                          (sprintf "\"Invalid words: %s\"" 
                            (String.concat ~sep:", " invalid_words))
                          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                    )
                )
          )
      | _ -> Dream.json ~status:`Bad_Request "\"Expected object\""
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    with _ ->
      Dream.json ~status:`Bad_Request "\"Invalid JSON\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
  )

let hint : Dream.route =
  Dream.get "/hint" (fun request ->
    let%lwt body = Dream.body request in
    try
      match Yojson.Basic.from_string body with 
      | `Assoc pairs ->
        begin
          let board_data = List.Assoc.find_exn pairs ~equal:String.equal "board" in
          let tiles =
            match board_data with
            | `Assoc board_pairs ->
              List.filter_map board_pairs ~f:(fun (coord, json) ->
                match json, String.split coord ~on:',' with
                | `String letter, [col_str; row_str] when String.length letter = 1 ->
                  (try
                    let col = Int.of_string (String.strip row_str) in
                    let row = Int.of_string (String.strip col_str) in
                    Some (Banana_gram.Tile.create (Tile.Position.create row col) (String.get letter 0))
                  with _ -> None)
                | _ -> None)
            | _ -> []
          in

          let rack_data = List.Assoc.find_exn pairs ~equal:String.equal "rack" in
          let rack =
            match rack_data with
            | `List rack_list ->
              List.filter_map rack_list ~f:(fun json ->
                match json with
                | `String letter when String.length letter = 1 ->
                  Some (String.get letter 0)
                | _ -> None)
            | _ -> []
          in

          match Banana_gram.Board.of_tiles tiles with
          | Error err ->
            Dream.json ~status:`Bad_Request 
              (sprintf "\"Error: %s\"" err)
              ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          
          | Ok board ->
              if Banana_gram.Board.is_empty board then
                Dream.json ~status:`Bad_Request "\"Board is empty\""
                  ~headers:[ ("Access-Control-Allow-Origin", "*") ]
              else
                match !solver_utils_ref with
                | None ->
                  Dream.json ~status:`OK "\"No hint available\""
                    ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                | Some utils ->
                  let hint = Solver.calculate_hint utils rack board in
                  match hint with
                  | None ->
                    Dream.json ~status:`OK "\"No hint available\""
                    ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                  | Some h ->
                    let message = Solver.hint_as_string h in
                    let hint_json = `String message |> Yojson.Basic.to_string in
                    Dream.json ~status:`OK
                      ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                      hint_json
        end
      | _ -> Dream.json ~status:`Bad_Request "\"Expected object\""
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    with _ ->
      Dream.json ~status:`Bad_Request "\"Invalid JSON\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
  )

let cors_preflight : Dream.route =
  Dream.options "/**" (fun _ ->
    Dream.respond ~status:`OK
      ~headers:[
        ("Access-Control-Allow-Origin", "*");
        ("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        ("Access-Control-Allow-Headers", "Content-Type");
      ]
      ""
  )

let () =
  Game_utils.load_dictionary "dictionary.txt" dictionary_ref;
  Game_utils.load_solver "dictionary.txt" "banana-dist.txt" solver_utils_ref;
  
  Dream.run ~port:8080
  @@ Dream.logger
  @@ Dream.router [
       Dream.get "/" (fun _ ->
         Dream.html "Bananagrams 2-player server is running!");
       cors_preflight;
       join_game;
       get_tiles;
       draw_tiles;
       hint;
       validate;
     ]


(*open Core
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

(*player state management*)
type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  last_active: float;
}

(*each player has their own tile and board*)
let players_ref : (string, player_state) Hashtbl.t = Hashtbl.create (module String)
let players_mutex = Lwt_mutex.create ()

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
*)