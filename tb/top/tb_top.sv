`timescale 1ns / 1ps

module tb_top;
  import uvm_pkg::*;
  import fifo_uvm_pkg::*;

  logic clk = 1'b0;
  always #5ns clk = ~clk;

  fifo_if #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) vif (
      clk
  );

  sync_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) dut (
      .clk     (clk),
      .rst_n   (vif.rst_n),
      .wr_en   (vif.wr_en),
      .wr_data (vif.wr_data),
      .rd_en   (vif.rd_en),
      .rd_data (vif.rd_data),
      .rd_valid(vif.rd_valid),
      .full    (vif.full),
      .empty   (vif.empty),
      .level   (vif.level)
  );

  sync_fifo_sva #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
  ) sva (
      .clk     (clk),
      .rst_n   (vif.rst_n),
      .wr_en   (vif.wr_en),
      .wr_data (vif.wr_data),
      .rd_en   (vif.rd_en),
      .rd_data (vif.rd_data),
      .rd_valid(vif.rd_valid),
      .full    (vif.full),
      .empty   (vif.empty),
      .level   (vif.level)
  );

  initial begin
    vif.rst_n   = 1'b0;
    vif.wr_en   = 1'b0;
    vif.rd_en   = 1'b0;
    vif.wr_data = '0;
    repeat (4) @(posedge clk);
    vif.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual fifo_if #(DATA_WIDTH, DEPTH))::set(null, "uvm_test_top.env.agent.*",
                                                              "vif", vif);
    run_test("fifo_base_test");
  end
endmodule
