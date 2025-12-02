open Core
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
let tile_bag = read_letter_list "../banana-dist.txt"

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

let validate : Dream.route =
  Dream.post "/validate" (fun request ->
    let%lwt body = Dream.body request in
      try
        let json = Yojson.Basic.from_string body in
        match json with
        | `Assoc pairs ->
            let board_map = List.fold pairs 
              ~init:(Map.empty (module String))
              ~f:(fun acc (coord_key, letter_json) ->
                match letter_json with
                | `String letter -> Map.add_exn acc ~key:coord_key ~data:letter
                | _ -> acc
              )
            in
            Map.iteri board_map ~f:(fun ~key ~data ->
              Printf.printf "Coordinate %s has letter '%s'\n%!" key data
            );
            
            Dream.json ~status:`OK "\"Board received successfully\""
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
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
  Dream.run ~port:8080
  @@ Dream.logger
  @@ Dream.router [
       
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

