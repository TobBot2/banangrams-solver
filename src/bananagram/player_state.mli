type player_state = {
  id: string;
  tiles: char list;
  board: (int * int * char) list; (* row, col, letter *)
  peel_tiles: char list;
}
(** The player state, with their tiles, board, id and additional peel tiles *)

val generate_player_id: unit -> string
(** Generate a unique string id based on time and an random number *)

val get_or_create_player: char list ref -> (string, player_state) Base.Hashtbl.t ->
string ->
player_state Lwt.t
(** Get the player from the hash table, or create a new one and add it if the player doesn't exist *)