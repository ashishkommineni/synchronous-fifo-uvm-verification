`timescale 1ns / 1ps

interface fifo_if #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16
) (
    input logic clk
);
  localparam int LEVEL_WIDTH = $clog2(DEPTH + 1);

  logic                   rst_n;
  logic                   wr_en;
  logic [ DATA_WIDTH-1:0] wr_data;
  logic                   rd_en;
  logic [ DATA_WIDTH-1:0] rd_data;
  logic                   rd_valid;
  logic                   full;
  logic                   empty;
  logic [LEVEL_WIDTH-1:0] level;

  clocking drv_cb @(negedge clk);
    output wr_en, wr_data, rd_en;
    input rd_data, rd_valid, full, empty, level;
  endclocking

  modport DUT(
      input clk, rst_n, wr_en, wr_data, rd_en,
      output rd_data, rd_valid, full, empty, level
  );
endinterface
