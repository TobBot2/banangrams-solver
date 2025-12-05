open Core


(** Signature for tiles used in words *)
module type TILE = sig
  type t [@@deriving sexp, compare, equal]
  type value_t [@@deriving sexp, compare, equal]
  
  module Value : sig
    type t = value_t
    val to_string : t -> string
  end
  
  val create : Tile.Position.t -> value_t -> t
  val position : t -> Tile.Position.t
  val value : t -> value_t
  val to_string : t -> string
  
  include Comparable.S with type t := t
end

(** Functor to create Word module for any tile type *)
module Make (T : TILE) = struct
  module Tile_type = T
  
  module T_list = struct
    type t = T.t list [@@deriving sexp, compare, equal]
  end
  include T_list
  include Comparable.Make(T_list)
  
  let create start values =
    List.mapi values ~f:(fun i v ->
      let pos = Tile.Position.create 
        (Tile.Position.row start) 
        (Tile.Position.col start + i) in
      T.create pos v)

    (** Increments the position horizontally - not sure if this is the best approach?*)
  
  let start word =
    match word with
    | [] -> failwith "Word.start: empty word"
    | tile :: _ -> T.position tile
  
  let values word =
    List.map word ~f:(fun tile -> T.value tile)
  
  let to_string word =
    values word
    |> List.map ~f:T.Value.to_string
    |> String.concat ~sep:""
  
  let length word =
    List.length word
  
  let is_empty word =
    List.is_empty word
  
  let tiles word = word
end

