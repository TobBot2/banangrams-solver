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
module Make (T : TILE) : sig
  module Tile_type : TILE with type t = T.t and type value_t = T.value_t
  
  (** A word is a list of tiles *)
  type t = T.t list [@@deriving sexp, compare, equal]
  
  val create :  Tile.Position.t -> T.value_t list -> t
  (** [create start values] creates a word starting at [start] position,
      placing values horizontally (incrementing column) *)
  
  val start : t ->  Tile.Position.t
  (** [start word] returns the position of the first tile.
      Raises [Failure] if word is empty *)
  
  val values : t -> T.value_t list
  (** [values word] returns the list of values from all tiles *)
  
  val to_string : t -> string
  (** [to_string word] converts word values to a string representation *)
  
  val length : t -> int
  (** [length word] returns the number of tiles in the word *)
  
  val is_empty : t -> bool
  (** [is_empty word] checks if the word has no tiles *)
  
  val tiles : t -> T.t list
  (** [tiles word] returns the list of tiles (same as the word itself) *)
  
  include Comparable.S with type t := t
end
