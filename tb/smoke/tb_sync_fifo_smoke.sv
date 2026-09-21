`timescale 1ns / 1ps

module tb_sync_fifo_smoke;
  localparam int DATA_WIDTH = 8;
  localparam int DEPTH = 8;
  localparam int LEVEL_WIDTH = $clog2(DEPTH + 1);

  logic clk;
  logic rst_n = 1'b0;
  logic wr_en = 1'b0;
  logic [DATA_WIDTH-1:0] wr_data = '0;
  logic rd_en = 1'b0;
  logic [DATA_WIDTH-1:0] rd_data;
  logic rd_valid;
  logic full;
  logic empty;
  logic [LEVEL_WIDTH-1:0] level;

  int checks = 0;
  initial clk = 1'b0;
  always #5 clk = ~clk;

  sync_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .*
  );
  sync_fifo_sva #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) sva (
      .clk,
      .rst_n,
      .wr_en,
      .wr_data,
      .rd_en,
      .rd_data,
      .rd_valid,
      .full,
      .empty,
      .level
  );

  task automatic push(input logic [DATA_WIDTH-1:0] data);
    @(negedge clk);
    wr_en   = 1'b1;
    wr_data = data;
    rd_en   = 1'b0;
    @(posedge clk);
    #1;
    wr_en = 1'b0;
  endtask

  task automatic pop_check(input logic [DATA_WIDTH-1:0] expected);
    @(negedge clk);
    rd_en = 1'b1;
    wr_en = 1'b0;
    @(posedge clk);
    #1;
    if (!rd_valid || rd_data !== expected)
      $fatal(1, "POP mismatch: expected=%02h actual=%02h valid=%0b", expected, rd_data, rd_valid);
    checks++;
    rd_en = 1'b0;
  endtask

  initial begin
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    #1;
    if (!empty || full || level != 0) $fatal(1, "Reset state is incorrect");

    for (int i = 0; i < DEPTH; i++) push(DATA_WIDTH'(8'h20 + i));
    @(posedge clk);
    #1;
    if (!full || level != LEVEL_WIDTH'(DEPTH)) $fatal(1, "FIFO did not become full");

    // Overflow must be blocked.
    push(8'hEE);
    if (level != LEVEL_WIDTH'(DEPTH)) $fatal(1, "Overflow changed FIFO level");

    for (int i = 0; i < DEPTH; i++) pop_check(DATA_WIDTH'(8'h20 + i));
    @(posedge clk);
    #1;
    if (!empty || level != 0) $fatal(1, "FIFO did not become empty");

    // Underflow must not create rd_valid.
    @(negedge clk);
    rd_en = 1'b1;
    @(posedge clk);
    #1;
    if (rd_valid) $fatal(1, "Underflow incorrectly asserted rd_valid");
    rd_en = 1'b0;

    // Simultaneous write/read preserves ordering.
    push(8'hA1);
    push(8'hB2);
    @(negedge clk);
    wr_en   = 1'b1;
    wr_data = 8'hC3;
    rd_en   = 1'b1;
    @(posedge clk);
    #1;
    if (!rd_valid || rd_data !== 8'hA1) $fatal(1, "Simultaneous operation returned wrong data");
    checks++;
    wr_en = 1'b0;
    rd_en = 1'b0;
    pop_check(8'hB2);
    pop_check(8'hC3);

    $display("SYNC_FIFO_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
