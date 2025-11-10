open Core

module type VALUE = Tile.VALUE
module type S = Tile.S

module Make (V : VALUE) = struct
  module Position = struct
    type t = int * int [@@deriving sexp, compare, equal]

    let create r c = (r, c)

    let row (r, _) = r
    let col (_, c) = c

    let up (r,c) = (r-1, c)
    let down (r,c) = (r+1, c)
    let right (r,c) = (r, c+1)
    let left (r,c) = (r, c-1)

    let neighbor dir (r,c) =
      match dir with
      | Direction.Horizontal -> right (r,c)  
      | Direction.Vertical -> down (r,c)

    let manhattan_distance (r1,c1) (r2,c2) = Int.abs (r1 - r2) + Int.abs (c1 - c2)
    
    let to_string (r,c) = Printf.sprintf "(%d,%d)" r c
    let of_string s =
      match String.split ~on:',' (String.strip ~drop:(fun ch -> Char.(ch = '(' || ch = ')' || ch = ' ')) s) with
      | [r;c] -> (Int.of_string r, Int.of_string c)
      | _ -> invalid_arg "Position.of_string"
  end

  module Value = V

  type t = { position : Position.t; value : Value.t } [@@deriving sexp, compare, equal]

  let create position value = { position; value }
  let position t = t.position
  let value t = t.value
  let to_string t = Printf.sprintf "%s@%s" (Value.to_string t.value) (Position.to_string t.position)

  include (struct type nonrec t = t [@@deriving sexp] end)
  include Comparable.Make(struct
    type nonrec t = t [@@deriving sexp, compare]
  end)
end

module CharValue = struct
  type t = char [@@deriving sexp, compare, equal]
  let of_char c = c
  let to_char c = c
  let to_string c = String.of_char c
  let is_letter c = Char.is_alpha c
  let uppercase c = Char.uppercase c
  let lowercase c = Char.lowercase c
  include Comparable.Make(struct
    type nonrec t = t [@@deriving sexp, compare]
  end)
end

include Make(CharValue)
