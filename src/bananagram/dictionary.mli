open Core

(** Dictionary type - a set of valid words *)
type t = String.Set.t [@@deriving sexp, compare]

val load : string -> (t, string) Result.t
(** [load filepath] loads a dictionary from a file.
    Each line in the file should be a single word.
    Returns Error if the file cannot be read. *)

val contains : t -> string -> bool
(** [contains dict word] checks if [word] is in the dictionary.
    Case-insensitive. *)

val empty : t
(** [empty] creates an empty dictionary *)
