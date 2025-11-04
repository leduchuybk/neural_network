
MODULE_NAME=neuron
TB_FILE_NAME=tb_$(MODULE_NAME)
SRC_FILES = src/*.sv sim/$(TB_FILE_NAME).sv
TOP_MODULE = $(TB_FILE_NAME)
SNAPSHOT_NAME = $(TB_FILE_NAME)_snapshot
WORK_LIB = work

.PHONY: all compile elaborate simulate clean

all: simulate

compile:
	@echo "--- 1. Parsing systemverilog files ---"
	xvlog -sv -work $(WORK_LIB) $(SRC_FILES) --define PRETRAINED

elaborate: compile
	@echo "--- 2. Elaborating Design snapshot (xelab) ---"
	xelab $(WORK_LIB).$(TOP_MODULE) -s $(SNAPSHOT_NAME) -debug typical --timescale 1ns/1ps

simulate: elaborate
	@echo "--- 3. Running simulation (xsim) ---"
	xsim $(SNAPSHOT_NAME) -tclbatch sim/sim.tcl

gui: simulate
	@echo "--- 4. Open waveform"
	xsim $(SNAPSHOT_NAME).wdb -gui &

clean:
	@echo "--- Cleaning up simulation output ---"
	rm -rf $(WORK_LIB) xsim.dir *.log *.jou *.pb *.wdb .Xil
