`timescale 1ns / 1ps

module sync_fifo #(
    parameter  int unsigned DATA_WIDTH  = 8,
    parameter  int unsigned DEPTH       = 16,
    localparam int unsigned ADDR_WIDTH  = $clog2(DEPTH),
    localparam int unsigned LEVEL_WIDTH = $clog2(DEPTH + 1)
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   wr_en,
    input  logic [ DATA_WIDTH-1:0] wr_data,
    input  logic                   rd_en,
    output logic [ DATA_WIDTH-1:0] rd_data,
    output logic                   rd_valid,
    output logic                   full,
    output logic                   empty,
    output logic [LEVEL_WIDTH-1:0] level
);

  initial begin
    if (DEPTH < 2 || (DEPTH & (DEPTH - 1)) != 0)
      $fatal(1, "DEPTH must be a power of two and at least 2");
  end

  logic [DATA_WIDTH-1:0] mem       [0:DEPTH-1];
  logic [  ADDR_WIDTH:0] wr_ptr_q;
  logic [  ADDR_WIDTH:0] rd_ptr_q;
  logic                  wr_accept;
  logic                  rd_accept;

  assign empty = (wr_ptr_q == rd_ptr_q);
  assign full  = (wr_ptr_q[ADDR_WIDTH] != rd_ptr_q[ADDR_WIDTH]) &&
                 (wr_ptr_q[ADDR_WIDTH-1:0] == rd_ptr_q[ADDR_WIDTH-1:0]);
  assign level = wr_ptr_q - rd_ptr_q;

  // A simultaneous read frees one location, so a write is legal even when full.
  // When empty, a simultaneous read/write does not bypass; the read is rejected.
  assign rd_accept = rd_en && !empty;
  assign wr_accept = wr_en && (!full || rd_accept);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_q <= '0;
      rd_ptr_q <= '0;
      rd_data  <= '0;
      rd_valid <= 1'b0;
    end else begin
      rd_valid <= rd_accept;

      if (wr_accept) begin
        mem[wr_ptr_q[ADDR_WIDTH-1:0]] <= wr_data;
        wr_ptr_q <= wr_ptr_q + 1'b1;
      end

      if (rd_accept) begin
        rd_data  <= mem[rd_ptr_q[ADDR_WIDTH-1:0]];
        rd_ptr_q <= rd_ptr_q + 1'b1;
      end
    end
  end

endmodule
