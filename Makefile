XRUN       ?= xrun
VERILATOR  ?= verilator-cli
TEST       ?= fifo_base_test
SEED       ?= random
UVM_VERBOSITY ?= UVM_MEDIUM

.PHONY: uvm regress smoke lint clean

uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top \
	  +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	  -svseed $(SEED) -access +rwc -coverage all -covoverwrite \
	  -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log

regress:
	@for seed in 11 29 47 83 101; do \
	  $(MAKE) uvm SEED=$$seed || exit 1; \
	done

lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/sync_fifo.sv

smoke:
	rm -rf build/obj_sync_fifo
	mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET \
	  --top-module tb_sync_fifo_smoke --Mdir build/obj_sync_fifo \
	  rtl/sync_fifo.sv tb/assertions/sync_fifo_sva.sv tb/smoke/tb_sync_fifo_smoke.sv
	bash -o pipefail -c './build/obj_sync_fifo/Vtb_sync_fifo_smoke | tee results_smoke.log'

clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
