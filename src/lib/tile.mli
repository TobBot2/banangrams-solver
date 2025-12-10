
open Core

(** Signature for tile values *)
module type VALUE = sig
  type t [@@deriving sexp, compare, equal]
  
  val to_string : t -> string 

  include Comparable.S with type t := t
end

(** Position module - same for all tile types *)
module Position : sig
  type t = int * int [@@deriving sexp, compare, equal]
  
  val create : int -> int -> t
  (** [create row col] creates a position *)
  
  val row : t -> int
  val col : t -> int
  
  val up : t -> t
  (** [up (r, c)] returns [(r-1, c)] - one position up *)
  
  val down : t -> t
  (** [down (r, c)] returns [(r+1, c)] - one position down *)
  
  val right : t -> t
  (** [right (r, c)] returns [(r, c+1)] - one position right *)
  
  val left : t -> t
  (** [left (r, c)] returns [(r, c-1)] - one position left *)
  
  val to_string : t -> string
  include Comparable.S with type t := t
end

module type TILE = sig
  type t [@@deriving sexp, compare, equal]
  type value_t [@@deriving sexp, compare, equal]
  
  module Value : sig
    type t = value_t
    val to_string : t -> string
  end
  
  val create : Position.t -> value_t -> t
  val position : t -> Position.t
  val value : t -> value_t
  val to_string : t -> string
  
  include Comparable.S with type t := t
end

(** Functor to create Tile module for any value type *)
module Make (V : VALUE) : TILE with type value_t = V.t
