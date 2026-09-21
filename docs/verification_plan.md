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

## Constrained-random intent

The transaction weights write-only, read-only, simultaneous, and idle cycles instead of leaving acceptance to an accidental uniform distribution. This drives steady-state traffic as well as boundary requests. The directed portion fills, overflows, drains, underflows, exercises simultaneous operations, and wraps pointers before the randomized phase begins. Scoreboard end-of-test checks reject an empty-traffic or partially drained run.
