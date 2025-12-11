open Core
open Lib
open Bananagram

(* Player state management *)
(*
type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  last_active: float;
}*)

(* Global game state *)
let players_ref : (string, Player_state.player_state) Hashtbl.t = Hashtbl.create (module String)
(*let players_mutex = Lwt_mutex.create ()*)

let dictionary_ref : Dictionary.t option ref = ref None

let solver_utils_ref : Solver.Utils.t option ref = ref None

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
(*let generate_player_id () =
  let timestamp = 
    Time_ns.now () 
    |> Time_ns.to_span_since_epoch 
    |> Time_ns.Span.to_int_sec
  in
  let random = Random.int 10000 in
  sprintf "player_%d_%d" timestamp random*)

(* Initialize or get player *)

(*
let get_or_create_player player_id : Player_state.player_state Lwt.t =
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
        tile_bag_ref := remaining;
        let current_time = 
          Time_ns.now () 
          |> Time_ns.to_span_since_epoch 
          |> Time_ns.Span.to_int_sec 
          |> Float.of_int
        in
        let new_player: Player_state.player_state= {
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
        *)

(* Join game - returns player ID *)
let join_game : Dream.route =
  Dream.post "/join" (fun _ ->
    let player_id = Player_state.generate_player_id () in
    let%lwt player = Player_state.get_or_create_player tile_bag_ref players_ref player_id in
    
    let response = `Assoc [
      ("playerId", `String player.id);
      ("tiles", `List (List.map player.tiles ~f:(fun c -> `String (String.make 1 c))));
      ("tilesRemaining", `Int (List.length !tile_bag_ref));
    ] |> Yojson.Basic.to_string in
    
    Dream.json ~status:`OK
      ~headers:[ ("Access-Control-Allow-Origin", "*") ]
      response
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
            (*let%lwt player = get_or_create_player player_id in
            let new_tiles, remaining = Game_utils.peek_random_tiles_from_bag !tile_bag_ref count in
            Printf.printf "Player %s requested %d — returned %d tiles: %s\n%!"
              player_id count (List.length new_tiles) (String.of_char_list new_tiles);
            *)
            let player_opt = Hashtbl.find players_ref player_id in
            match player_opt with
            | None ->
                Lwt.return_error "Player not found"
            | Some player ->
                let new_tiles, remaining = Game_utils.peek_random_tiles_from_bag !tile_bag_ref count in
                Printf.printf "Player %s requested %d — returned %d tiles: %s\n%!"
                  player_id count (List.length new_tiles) (String.of_char_list new_tiles);
                
              tile_bag_ref := remaining
            ;
            Printf.printf "Tiles left in bag: %d\n%!" (List.length !tile_bag_ref);
            
            let all_tiles = player.tiles @ new_tiles in
            let updated_player = { player with tiles = all_tiles } in
            Hashtbl.set players_ref ~key:player_id ~data:updated_player;
            
            (*Lwt.return_ok all_tiles*)
            Lwt.return_ok new_tiles
          ) in
                    (match updated_tiles with
          | Ok tiles ->
              let response = `Assoc [
                ("tiles", `List (List.map tiles ~f:(fun c -> `String (String.make 1 c))));
                ("tilesRemaining", `Int (List.length !tile_bag_ref));
              ] |> Yojson.Basic.to_string in
              
              Dream.json ~status:`OK
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
                response
          | Error msg ->
              Dream.json ~status:`Bad_Request 
                (sprintf "\"%s\"" msg)
                ~headers:[ ("Access-Control-Allow-Origin", "*") ]
          )
      | _ -> Dream.json ~status:`Bad_Request "\"Invalid request\""
          ~headers:[ ("Access-Control-Allow-Origin", "*") ]
    with _ ->
      Dream.json ~status:`Bad_Request "\"Invalid JSON\""
        ~headers:[ ("Access-Control-Allow-Origin", "*") ]
  )

(* Get current game state - tiles remaining *)
let game_state : Dream.route =
  Dream.get "/game_state" (fun _ ->
    let response = `Assoc [
      ("tilesRemaining", `Int (List.length !tile_bag_ref));
    ] |> Yojson.Basic.to_string in
    
    Dream.json ~status:`OK
      ~headers:[ ("Access-Control-Allow-Origin", "*") ]
      response
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
  Dream.post "/hint" (fun request ->
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
       game_state;
       draw_tiles;
       hint;
       validate;
     ]