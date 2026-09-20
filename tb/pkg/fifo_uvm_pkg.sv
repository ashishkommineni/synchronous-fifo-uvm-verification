`timescale 1ns / 1ps

package fifo_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam int DATA_WIDTH = 8;
  localparam int DEPTH = 16;

  class fifo_item extends uvm_sequence_item;
    rand bit                      wr_en;
    rand bit                      rd_en;
    rand bit     [DATA_WIDTH-1:0] wr_data;
    bit          [DATA_WIDTH-1:0] rd_data;
    bit                           rd_valid;
    bit                           full;
    bit                           empty;
    int unsigned                  level;
    bit                           wr_accepted;
    bit                           rd_accepted;

    constraint c_activity {
      {
        wr_en, rd_en
      } dist {
        2'b00 := 1,
        2'b01 := 3,
        2'b10 := 3,
        2'b11 := 3
      };
    }

    `uvm_object_utils_begin(fifo_item)
      `uvm_field_int(wr_en, UVM_DEFAULT)
      `uvm_field_int(rd_en, UVM_DEFAULT)
      `uvm_field_int(wr_data, UVM_HEX)
      `uvm_field_int(rd_data, UVM_HEX)
      `uvm_field_int(rd_valid, UVM_DEFAULT)
      `uvm_field_int(full, UVM_DEFAULT)
      `uvm_field_int(empty, UVM_DEFAULT)
      `uvm_field_int(level, UVM_DEC)
      `uvm_field_int(wr_accepted, UVM_DEFAULT)
      `uvm_field_int(rd_accepted, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "fifo_item");
      super.new(name);
    endfunction
  endclass

  class fifo_sequencer extends uvm_sequencer #(fifo_item);
    `uvm_component_utils(fifo_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class fifo_driver extends uvm_driver #(fifo_item);
    `uvm_component_utils(fifo_driver)
    virtual fifo_if #(DATA_WIDTH, DEPTH) vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, DEPTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "fifo_if was not supplied through uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
      vif.drv_cb.wr_en   <= 1'b0;
      vif.drv_cb.rd_en   <= 1'b0;
      vif.drv_cb.wr_data <= '0;
      wait (vif.rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(req);
        vif.drv_cb.wr_en   <= req.wr_en;
        vif.drv_cb.rd_en   <= req.rd_en;
        vif.drv_cb.wr_data <= req.wr_data;
        @(vif.drv_cb);
        vif.drv_cb.wr_en <= 1'b0;
        vif.drv_cb.rd_en <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)
    virtual fifo_if #(DATA_WIDTH, DEPTH) vif;
    uvm_analysis_port #(fifo_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, DEPTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "fifo_if was not supplied through uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
      fifo_item tr;
      wait (vif.rst_n === 1'b1);
      forever begin
        @(posedge vif.clk);
        tr             = fifo_item::type_id::create("tr");
        tr.wr_en       = vif.wr_en;
        tr.rd_en       = vif.rd_en;
        tr.wr_data     = vif.wr_data;
        tr.full        = vif.full;
        tr.empty       = vif.empty;
        tr.level       = vif.level;
        tr.rd_accepted = vif.rd_en && !vif.empty;
        tr.wr_accepted = vif.wr_en && (!vif.full || tr.rd_accepted);
        #1ps;
        tr.rd_data  = vif.rd_data;
        tr.rd_valid = vif.rd_valid;
        ap.write(tr);
      end
    endtask
  endclass

  class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)
    fifo_sequencer sqr;
    fifo_driver    drv;
    fifo_monitor   mon;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = fifo_monitor::type_id::create("mon", this);
      if (get_is_active() == UVM_ACTIVE) begin
        sqr = fifo_sequencer::type_id::create("sqr", this);
        drv = fifo_driver::type_id::create("drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (get_is_active() == UVM_ACTIVE) drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp #(fifo_item, fifo_scoreboard) analysis_export;
    bit [DATA_WIDTH-1:0] model_q[$];
    int unsigned writes;
    int unsigned reads;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction

    function void write(fifo_item tr);
      bit [DATA_WIDTH-1:0] expected;

      // Read first: this preserves old head data during a full simultaneous R/W.
      if (tr.rd_accepted) begin
        if (model_q.size() == 0)
          `uvm_error("MODEL_UDF", "DUT accepted a read while reference queue was empty")
        else begin
          expected = model_q.pop_front();
          reads++;
          if (!tr.rd_valid) `uvm_error("RD_VALID", "Accepted read did not assert rd_valid")
          else if (tr.rd_data !== expected)
            `uvm_error("DATA", $sformatf("Expected 0x%0h, received 0x%0h", expected, tr.rd_data))
        end
      end else if (tr.rd_valid) begin
        `uvm_error("SPURIOUS", "rd_valid asserted without an accepted read")
      end

      if (tr.wr_accepted) begin
        model_q.push_back(tr.wr_data);
        writes++;
      end

      if (model_q.size() != tr.level)
        `uvm_error("LEVEL", $sformatf(
                   "Model level %0d differs from DUT level %0d", model_q.size(), tr.level))
    endfunction

    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (model_q.size() != 0)
        `uvm_error("NOT_EMPTY", $sformatf(
                   "%0d expected items remained at end of test", model_q.size()))
      if (writes == 0 || reads == 0)
        `uvm_error("NO_TRAFFIC", "Test did not complete both writes and reads")
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("FIFO_SUMMARY", $sformatf("Checked %0d writes and %0d reads", writes, reads),
                UVM_LOW)
    endfunction
  endclass

  class fifo_coverage extends uvm_subscriber #(fifo_item);
    `uvm_component_utils(fifo_coverage)
    fifo_item sample;

    covergroup fifo_cg;
      option.per_instance = 1;
      cp_operation: coverpoint {
        sample.wr_en, sample.rd_en
      } {
        bins idle = {2'b00}; bins read = {2'b01}; bins write = {2'b10}; bins both = {2'b11};
      }
      cp_level: coverpoint sample.level {
        bins empty = {0};
        bins low = {[1 : DEPTH / 2 - 1]};
        bins half = {DEPTH / 2};
        bins high = {[DEPTH / 2 + 1 : DEPTH - 1]};
        bins full = {DEPTH};
      }
      cp_status: coverpoint {sample.full, sample.empty};
      cx_operation_status: cross cp_operation, cp_status;
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      fifo_cg = new();
    endfunction

    function void write(fifo_item t);
      sample = t;
      fifo_cg.sample();
    endfunction
  endclass

  class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)
    fifo_agent      agent;
    fifo_scoreboard sb;
    fifo_coverage   cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = fifo_agent::type_id::create("agent", this);
      sb    = fifo_scoreboard::type_id::create("sb", this);
      cov   = fifo_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass

  class fifo_random_sequence extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_random_sequence)
    int unsigned count = 300;

    function new(string name = "fifo_random_sequence");
      super.new(name);
    endfunction

    task body();
      repeat (count) begin
        req = fifo_item::type_id::create("req");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "fifo_item randomization failed")
        finish_item(req);
      end

      // Drain long enough to empty a depth-16 FIFO.
      repeat (DEPTH + 2) begin
        req = fifo_item::type_id::create("drain_req");
        start_item(req);
        req.wr_en   = 1'b0;
        req.rd_en   = 1'b1;
        req.wr_data = '0;
        finish_item(req);
      end
    endtask
  endclass

  class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)
    fifo_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      fifo_random_sequence seq;
      phase.raise_objection(this);
      seq = fifo_random_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      repeat (3) @(posedge env.agent.mon.vif.clk);
      phase.drop_objection(this);
    endtask
  endclass

endpackage
