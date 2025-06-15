# Ledgrd

An OCaml daemon that manages ledger entries

## Quick local test

`echo '{"op": "list"}' | socat - UNIX-CONNECT:/tmp/reznledgr.sock`
