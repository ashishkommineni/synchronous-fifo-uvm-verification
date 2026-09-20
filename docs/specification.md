# Synchronous FIFO Specification

## Functional contract

The FIFO stores `DEPTH` words of `DATA_WIDTH` bits under one clock. `DEPTH` must be a power of two. Reset is asynchronous, active low, and clears pointers, `rd_valid`, flags, and occupancy state.

| Condition | Write result | Read result |
|---|---|---|
| Normal write (`wr_en && !full`) | Accepted | — |
| Normal read (`rd_en && !empty`) | — | Accepted; `rd_valid` pulses for one cycle |
| Write while full, no read | Rejected | — |
| Read while empty | — | Rejected; `rd_valid=0` |
| Simultaneous read/write, normal occupancy | Both accepted | Old head is returned |
| Simultaneous read/write while full | Both accepted | Read frees the location used by the write |
| Simultaneous read/write while empty | Write accepted | Read rejected; no fall-through bypass |

`level` reports the number of stored words from 0 through `DEPTH`. Data is returned in first-in, first-out order.

## Design decisions

- A wrap bit is added to each pointer. Equal index bits with different wrap bits means full; complete pointer equality means empty.
- Memory read data is registered, producing a one-cycle `rd_valid` response.
- The design intentionally uses a non-fall-through empty behavior because it gives an unambiguous acceptance contract.
