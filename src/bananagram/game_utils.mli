val read_letter_list: string -> char list

val load_dictionary: string -> Dictionary.t option ref -> unit

val load_solver: string -> string -> Solver.Utils.t option ref -> unit

val peek_random_tiles_from_bag: char list -> int -> char list * char list