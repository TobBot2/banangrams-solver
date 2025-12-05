open Core

(** Signature for tiles used in boards *)
module type TILE = sig
  type t [@@deriving sexp, compare, equal]
  type value_t [@@deriving sexp, compare, equal]
  
  val create : Tile.Position.t -> value_t -> t
  val position : t -> Tile.Position.t
  val value : t -> value_t
  
  include Comparable.S with type t := t
end

(** Functor to create Board module for any tile type *)
module Make (T : TILE) : sig
  module Tile_type : TILE with type t = T.t and type value_t = T.value_t
  
  (** A board is a map from Position to tile values *)
  type t = T.value_t Map.M(Tile.Position).t [@@deriving sexp, compare]
  
  val empty : t
  (** [empty] creates an empty board *)
  
  val set : T.t -> t -> t
  (** [set tile board] adds a tile to the board at its position *)
  
  val remove : Tile.Position.t -> t -> t
  (** [remove pos board] removes the tile at position [pos] *)
  
  val get : Tile.Position.t -> t -> T.value_t option
  (** [get pos board] returns the value at position [pos], if any *)
  
  val get_tile : Tile.Position.t -> t -> T.t option
  (** [get_tile pos board] returns the tile at position [pos], if any *)
  
  val mem : Tile.Position.t -> t -> bool
  (** [mem pos board] checks if there's a tile at position [pos] *)
  
  val to_tiles : t -> T.t list
  (** [to_tiles board] converts the board to a list of tiles *)
  
  val positions : t -> Tile.Position.t list
  (** [positions board] returns all occupied positions *)
  
  val is_empty : t -> bool
  (** [is_empty board] checks if the board has no tiles *)
  
  val size : t -> int
  (** [size board] returns the number of tiles on the board *)
  
  val of_tiles : T.t list -> (t, string) Result.t
  (** [of_tiles tiles] creates a board from a list of tiles.
      Returns an error if there are duplicate positions *)
end
