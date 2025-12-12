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
   for other board games")
   (depends
    (ounit2 (>= 2.2.7)) ; for each opam dependency list the version
    (core (>= 0.17.1)) ; `opam list core` will display which version of core you have
 ))