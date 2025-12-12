val read_letter_list: string -> char list
(** file I/O helper function*)

val peek_random_tiles_from_bag: char list -> int -> char list * char list
(** peeks a number of tiles from the tile bag and removes them. Returns the tiles and the remaining tiles in the bag*)