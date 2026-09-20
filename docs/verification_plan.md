# Verification Plan

## Features and checkers

| Feature | Stimulus | Checker/coverage |
|---|---|---|
| Reset state | Initial reset | Flag and level assertions |
| FIFO ordering | Directed and random traffic | Queue-based scoreboard |
| Full/empty boundaries | Fill, drain, overflow, underflow | SVA plus level coverage |
| Simultaneous read/write | Random and directed | Scoreboard; operation/status cross |
| Overflow protection | Writes while full | Stable model depth |
| Underflow protection | Reads while empty | `rd_valid` assertion |
| Occupancy | All traffic | Scoreboard-to-`level` comparison |

## Closure criteria

- Zero UVM errors/fatals across the five-seed regression.
- All assertions pass.
- All operation bins, empty/full level bins, and simultaneous-operation crosses are hit.
- Verilator smoke test prints `SYNC_FIFO_SMOKE_PASS`.
