open Core

type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  last_active: float;
}

let generate_player_id () =
  let timestamp = 
    Time_ns.now () 
    |> Time_ns.to_span_since_epoch 
    |> Time_ns.Span.to_int_sec
  in
  let random = Random.int 10000 in
  sprintf "player_%d_%d" timestamp random