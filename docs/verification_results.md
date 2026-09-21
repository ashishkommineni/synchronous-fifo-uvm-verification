# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings |
| Executable RTL + SVA smoke | PASS | `SYNC_FIFO_SMOKE_PASS checks=11` |
| Parameter elaboration | PASS | 16-bit data / depth-4 variant passed strict lint |
| UVM source compile/elaboration | PASS | Complete hierarchy compiled against Accellera UVM `78c0654` |

```text
SYNC_FIFO_SMOKE_PASS checks=11
```

The executable verifies reset state, ordered fill/drain, blocked overflow/underflow, simultaneous read/write ordering, and pointer wraparound. Live SVA checks flag/level consistency, underflow blocking, and known data on accepted writes and valid reads.

## Second-pass findings corrected

- Data-known assertions now use the previously unobserved payload ports.
- Assertion comparisons use explicit occupancy-width casts, leaving the run warning-free.
- SVA is instantiated in the portable test, and `pipefail` propagates failures through logging.

## Xcelium boundary

No Xcelium runtime or functional-coverage percentage is claimed in this environment. Full UVM source elaboration passed. Run the five-seed `make regress` on the licensed host and require zero UVM errors/fatals, passing assertions, a drained scoreboard, and planned coverage closure.
