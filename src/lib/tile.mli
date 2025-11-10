open Core

(** Tile module representing a character placed at a position on the board *)
module type VALUE = sig
  type t [@@deriving sexp, compare, equal]

  val of_char : char -> t
  val to_char : t -> char
  val to_string : t -> string

  val is_letter : t -> bool
  val uppercase : t -> t
  val lowercase : t -> t

  include Comparable.S with type t := t
end

module type S = sig
  module Position : sig
    type t = int * int [@@deriving sexp, compare, equal]

    val create : int -> int -> t
    val row : t -> int
    val col : t -> int

    (** Navigation (pure position math) *)
    val up : t -> t      (** (r-1, c) *)
    val down : t -> t    (** (r+1, c) *)
    val right : t -> t   (** (r, c+1) *)
    val left : t -> t    (** (r, c-1) *)

    val neighbor : Direction.t -> t -> t
    val manhattan_distance : t -> t -> int
    val to_string : t -> string
    val of_string : string -> t

    include Comparable.S with type t := t
  end

  module Value : VALUE

  (** A tile is a value at a position *)
  type t = {
    position : Position.t;
    value : Value.t;
  } [@@deriving sexp, compare, equal]

module Position : sig
  type t = int * int [@@deriving sexp, compare, equal]

  (** Construction *)
  val create : Position.t -> Value.t -> t
  (** For the default [CharValue], this is [Position.t -> char -> t] *)

  (** Accessors *)
  val position : t -> Position.t
  val value : t -> Value.t

  (** Display *)
  val to_string : t -> string  (** e.g., "C@(0,0)" *)

  include Comparable.S with type t := t
  include Sexpable.S with type t := t
end

module Make (V : VALUE) : S with module Value = V

(** char-based tiles *)
module CharValue : VALUE with type t = char

include S with module Value = CharValue