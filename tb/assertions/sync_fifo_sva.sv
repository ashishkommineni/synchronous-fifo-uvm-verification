`timescale 1ns / 1ps

module sync_fifo_sva #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16,
    localparam int LEVEL_WIDTH = $clog2(DEPTH + 1)
) (
    input logic                   clk,
    input logic                   rst_n,
    input logic                   wr_en,
    input logic [ DATA_WIDTH-1:0] wr_data,
    input logic                   rd_en,
    input logic [ DATA_WIDTH-1:0] rd_data,
    input logic                   rd_valid,
    input logic                   full,
    input logic                   empty,
    input logic [LEVEL_WIDTH-1:0] level
);

  default clocking cb @(posedge clk);
  endclocking
  default disable iff (!rst_n); ap_flags_exclusive :
  assert property (!(full && empty))
  else $error("FIFO cannot be full and empty simultaneously");

  ap_level_in_range :
  assert property (level <= DEPTH)
  else $error("FIFO level exceeded DEPTH");

  ap_empty_level :
  assert property (empty |-> level == 0)
  else $error("empty asserted with non-zero level");

  ap_full_level :
  assert property (full |-> level == DEPTH)
  else $error("full asserted before the FIFO reached DEPTH");

  ap_underflow_blocked :
  assert property ((empty && rd_en) |=> !rd_valid)
  else $error("Read completed while FIFO was empty");

  cp_full_simultaneous_read_write :
  cover property (full && wr_en && rd_en);
  cp_empty_simultaneous_read_write :
  cover property (empty && wr_en && rd_en);

endmodule
