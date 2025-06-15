(lang dune 3.17)

(name rezn-ledgr)

(generate_opam_files true)

(license MIT)

(maintainers "Andrea Mancuso <andrea@andreamancuso.dev>")

(authors "Andrea Mancuso <andrea@andreamancuso.dev>")

(source
 (github rezn-project/rezn-ledgr))

(package
 (allow_empty)
 (name rezn-ledgr)
 (synopsis "Rezn Ledgr")
 (description "Local daemon for storage and sync of rezn ledger entries")
 (depends
  (base64
   (and
    (>= 3.5.0)
    (< 4.0.0)))
  (cmdliner
   (>= 1.3.0))
  (digestif
   (>= 1.3.0))
  (yojson
   (>= 2.2.2))
  ppx_expect))
