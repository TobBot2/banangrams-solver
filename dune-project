(lang dune 3.16)
(generate_opam_files true)
  (authors "Malavika Nair" "Trevor Black" "Lulu Grubb")
  (maintainers "lgrubb3@jhu.edu" "mnair13@jhu.edu" "tblack20@jhu.edu")
  (package
   (name banangrams-solver)
   (allow_empty)
   (synopsis "An OCaml library for playing bananagrams")
   (description "This package uses a solver algorithm with letter-value heuristics to suggest words 
   in a bananagrams game, and includes a library representation of board/word/tile that can be used
   for other tile board games")
   (depends
    (ounit2 (>= 2.2.7)) ; for each opam dependency list the version
    (core (>= 0.17.1)) ; `opam list core` will display which version of core you have
    (yojson (>= 1.7.0))
    (dream (>= 1.0.0))
    (dune (>= 3.16))
    (ppx_deriving
        (>= 5.2.1))
    (ppx_deriving_yojson
      (>= 3.7.0))
    (lwt
      (>= 5.4.0))
    (ppx_jane
      (>= v0.16.0))
    (bisect_ppx
      (>= 2.8.3))))