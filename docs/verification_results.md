# Verification results

Validation date: 2026-09-20

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint` completed with Verilator |
| Executable RTL smoke test | PASS | `SYNC_FIFO_SMOKE_PASS checks=11` |
| UVM source compile/elaboration lint | PASS | `sim/files.f`, assertions, and UVM package compiled against Accellera UVM core commit `78c0654` |

The smoke test covers reset state, ordered traffic, fill/drain, overflow and underflow blocking, simultaneous read/write at full, and pointer wraparound.

## Xcelium status

Cadence Xcelium was not installed in the validation environment, so no Xcelium runtime result is claimed. On a licensed Xcelium host, run `make uvm` for one seeded test or `make regress` for the five-seed regression. A passing run must finish with zero `UVM_ERROR` and zero `UVM_FATAL` messages.
