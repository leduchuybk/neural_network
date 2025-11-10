
MODULE_NAME = dnn
TB_FILE_NAME = tb_$(MODULE_NAME)
SRC_FILES  = ../neuron/src/*.sv
SRC_FILES += src/*.sv
SRC_FILES += sim/$(TB_FILE_NAME).sv
TOP_MODULE = $(TB_FILE_NAME)
SNAPSHOT_NAME = $(TB_FILE_NAME)_snapshot
WORK_LIB = work

MAXTESTSAMPLES ?= 10
SETUP = -i ./sim --define PRETRAINED --define MAXTESTSAMPLES=$(MAXTESTSAMPLES)

TEMPLATE_FILE = ./sim/layer_parameter.sv.template
OUTPUT_FILE = ./sim/layer_parameter.sv
WB_DIR = $(PWD)/sim/training/w_b/
TEST_DIR = $(PWD)/sim/training/testData/


.PHONY: all path compile elaborate simulate clean

all: simulate

path:
	@echo "--- 0. Set up path to initialized data ---"
	sed "s|PATH_TO_WB|$(WB_DIR)|g" $(TEMPLATE_FILE) > $(OUTPUT_FILE)_tmp
	sed "s|PATH_TO_TEST|$(TEST_DIR)|g" $(OUTPUT_FILE)_tmp > $(OUTPUT_FILE)
	rm $(OUTPUT_FILE)_tmp

compile: path
	@echo "--- 1. Parsing systemverilog files ---"
	xvlog -sv -work $(WORK_LIB) $(SRC_FILES) $(SETUP)

elaborate: compile
	@echo "--- 2. Elaborating Design snapshot (xelab) ---"
	xelab $(WORK_LIB).$(TOP_MODULE) -s $(SNAPSHOT_NAME) -debug typical --timescale 1ns/1ps $(SETUP)

simulate: elaborate
	@echo "--- 3. Running simulation (xsim) ---"
	xsim $(SNAPSHOT_NAME) -tclbatch sim/sim.tcl

gui: simulate
	@echo "--- 4. Open waveform"
	xsim $(SNAPSHOT_NAME).wdb -gui &

clean:
	@echo "--- Cleaning up simulation output ---"
	rm -rf $(WORK_LIB) xsim.dir *.log *.jou *.pb *.wdb .Xil
