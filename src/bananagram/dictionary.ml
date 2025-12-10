open Core

(** Dictionary type - a set of valid words *)
type t = String.Set.t [@@deriving sexp, compare]

let load filepath =
  try
    let lines = In_channel.read_lines filepath in
    let words = 
      List.map lines ~f:String.uppercase
      |> String.Set.of_list 
    in
    Ok words
  with
  | Sys_error msg -> Error (sprintf "Failed to load dictionary: %s" msg)

let contains dict word =
  Set.mem dict (String.uppercase word)

let empty = String.Set.empty

let of_list words =
  List.map words ~f:String.uppercase
  |> String.Set.of_list

let size dict =
  Set.length dict