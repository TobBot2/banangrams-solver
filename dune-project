(lang dune 3.16)
(generate_opam_files true)
  (authors "Malavika Nair" "Trevor Black" "Lulu Grubb")
  (maintainers "lgrubb3@jhu.edu")
  (package
   (name banangrams-solver) ; put in your own project name here
   (allow_empty)
   (synopsis "An OCaml library for playing bananagrams")
   (description "A longer description")
   (depends
    (ounit2 (>= 2.2.7)) ; for each opam dependency list the version
    (core (>= 0.17.1)) ; `opam list core` will display which version of core you have
 ))