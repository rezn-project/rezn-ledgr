# Ledgrd

An OCaml daemon that manages ledger entries

## Quick local test

```bash
echo '{"op":"list"}' \
| curl --unix-socket /tmp/reznledgr.sock \
       -H 'Content-Type: application/json' \
       -d @- \
       http://localhost/
```
