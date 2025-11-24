(*open Core*)
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

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/**" (Dream.static "../client/dist"); (*May only work in dev mode?*)
  ]

