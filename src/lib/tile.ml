open Core

module Position = struct
  type t = int * int [@@deriving sexp, compare, equal]
  
  let create row col = (row, col)
  
  let row (r, _) = r
  let col (_, c) = c
  
  let north (row, col) = (row - 1, col)
  let south (row, col) = (row + 1, col)
  let east (row, col) = (row, col + 1)
  let west (row, col) = (row, col - 1)
  
  let neighbor dir pos =
    match dir with
    | Direction.Horizontal -> east pos
    | Direction.Vertical -> south pos
  
  let to_string (row, col) = sprintf "(%d,%d)" row col
  
  let of_string s = Scanf.sscanf s "(%d,%d)" (fun r c -> (r, c))
  
  include Comparable.Make(struct
    type nonrec t = t [@@deriving sexp, compare]
  end)
end

module Value = struct
  type t = char [@@deriving sexp, compare, equal]
  let of_char c = c
  let to_char t = t
  let to_string c = String.make 1 c
  
  include Comparable.Make(struct
    type nonrec t = t [@@deriving sexp, compare]
  end)
end

type t = {
  position : Position.t;
  value : Value.t;
} [@@deriving sexp, compare, equal]

let create position value = { position; value }

let position tile = tile.position

let value tile = tile.value

let to_string tile =
  sprintf "%s@%s" 
    (Value.to_string tile.value)
    (Position.to_string tile.position)

let map_value f tile = { tile with value = f tile.value }

let move_to new_pos tile = { tile with position = new_pos }

let move dir tile =
  let new_pos = Position.neighbor dir tile.position in
  move_to new_pos tile

(* This generates comparison operators and Tile.Map, Tile.Set I need it this way becuase the type was messed up otherwise *)
include Comparable.Make(struct
  type nonrec t = t [@@deriving sexp, compare]
end)