open Core

module Position = struct
  type t = int * int [@@deriving sexp, compare, equal]
  
  let to_string (row, col) = 
    sprintf "(%d,%d)" row col
  
  let of_string s =

end

module Value = struct
  type t = char [@@deriving sexp, compare, equal]
  
  let to_string c = String.make 1 c
  
  let of_char c = c
  
  let to_char t = t
end

type t = {
  position : Position.t;
  value : Value.t;
} [@@deriving sexp, compare, equal]

let create position value = 
  { position; value }

let position tile = 
  tile.position

let value tile = 
  tile.value

let to_string tile =
  sprintf "%s@%s" 
    (Value.to_string tile.value)
    (Position.to_string tile.position)

let map_value f tile =
  { tile with value = f tile.value }

let move_to new_pos tile =
  { tile with position = new_pos }

include Comparable.Make(struct
  type nonrec t = t [@@deriving sexp, compare]
end)