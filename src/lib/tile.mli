
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

(** Functor to create Tile module for any value type *)
module Make (V : VALUE) : sig
  module Value : VALUE with type t = V.t
  
  (** A tile is Record with a value and position *)
  type t = {
    position : Position.t;
    value : Value.t;
  } [@@deriving sexp, compare, equal]
  
  val create : Position.t -> V.t -> t
  (** Create a tile with a position and value *)
  
  val position : t -> Position.t
  (** Get the position of the tile *)
  
  val value : t -> Value.t
  (** Get the value of the tile *)
  
  val to_string : t -> string
  (** String representation: "V@(row,col)" *)

end

module Value : sig
  type t = char [@@deriving sexp, compare, equal]

  val to_string : t -> string
  
  include Comparable.S with type t := t
end

type t = {
  position : Position.t;
  value : Value.t;
} [@@deriving sexp, compare, equal]

val create : Position.t -> Value.t -> t
(** Create a tile with a position and value *)

val position : t -> Position.t
(** Get the position of the tile *)

val value : t -> Value.t
(** Get the value of the tile *)

val to_string : t -> string
(** String representation of tile *)
