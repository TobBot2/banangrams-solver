open Core

type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  peel_tiles: char list;
}

let generate_player_id () =
  let timestamp = 
    Time_ns.now () 
    |> Time_ns.to_span_since_epoch 
    |> Time_ns.Span.to_int_sec
  in
  let random = Random.int 10000 in
  sprintf "player_%d_%d" timestamp random

(*mutex to keep track of players joined and prevent race conditions when joining*)  
let players_mutex = Lwt_mutex.create ()


let get_or_create_player tile_bag_ref players_ref player_id : player_state Lwt.t =
  Lwt_mutex.with_lock players_mutex (fun () ->
    match Hashtbl.find players_ref player_id with
    | Some player ->
        Hashtbl.set players_ref ~key:player_id ~data:player;
        Lwt.return player
    | None ->
        (* Create new player with initial tiles *)
        let tiles, remaining = Game_utils.peek_random_tiles_from_bag !tile_bag_ref 21 in
        tile_bag_ref := remaining;
        let new_player: player_state= {
          id = player_id;
          tiles = tiles;
          board = [];
          peel_tiles = [];
        } in
        Hashtbl.set players_ref ~key:player_id ~data:new_player;
        Printf.printf "Created new player: %s\n%!" player_id;
        let _ = new_player.board in (*dummy to avoid build error*)
        Lwt.return new_player
  )