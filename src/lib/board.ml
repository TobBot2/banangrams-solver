

module Board = Map.Make(struct type t = Tile.t [@@deriving sex, compare] end)
