
CONTAINER_ENGINE ?= docker

PWD = $(shell pwd)
CONTAINER_ARGS = run --rm -v $(PWD)/../:/wrk -w /wrk/uart

YOSYS=yosys
NEXTPNR=nextpnr-ecp5
ECPPACK=ecppack
BSC=bsc

# filenames
TARGET_NAME=Top
TOP=Top
MOD_NAME=mk$(TOP)
TEST_NAME=TestbenchUARTMirror
# TestbenchUARTMirror
TEST_MOD=mk$(TEST_NAME)

# directories
BUILD=build
VERILOG=$(BUILD)/verilog
SIM_DIR=$(BUILD)/sim

TARGET=$(BUILD)/$(TARGET_NAME)

COMMON=../common/

BLUEIMPORT=$(COMMON):+

COMPILER=$(BSC)

all: ${TARGET}.bit


prep_dirs: clean
	mkdir -p $(BUILD)
	mkdir -p $(VERILOG)
	mkdir -p $(SIM_DIR)

compile: $(TOP).bsv prep_dirs
	$(COMPILER) -bdir $(BUILD) -p $(BLUEIMPORT) -sim -g $(MOD_NAME) -u $< 2>&1 > $(BUILD)/build.log
	$(CLEAR)

gen_verilog: $(TOP).bsv prep_dirs
	$(COMPILER) -bdir $(BUILD) \
		-p $(BLUEIMPORT) \
		-remove-dollar -u -verilog \
		-show-schedule \
		-show-range-conflict \
		-vdir $(VERILOG) -g $(MOD_NAME) $<
	echo "\n\`include \"$(COMMON)lib_imports.v\"" >> $(VERILOG)/$(MOD_NAME).v

$(TARGET).json: gen_verilog 
	$(YOSYS) -p " \
		read_verilog $(VERILOG)/$(MOD_NAME).v;\
		synth_ecp5 -top $(MOD_NAME) -json $@;" \
	$(shell find $(VERILOG) -type f -name "*.v") ecp5_pll.v pll.v > $(BUILD)/yosys_build.log

$(TARGET)_out.config: $(TARGET).json
	$(NEXTPNR) --25k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf $(TARGET_NAME).lpf --freq 65 2> $(BUILD)/nextpnr_build.log

$(TARGET).bit: $(TARGET)_out.config
	$(ECPPACK) --compress --svf $(TARGET).svf $< $@

${TARGET}.svf : ${TARGET}.bit

compile_test: $(TEST_NAME).bsv prep_dirs
	$(COMPILER) -p $(BLUEIMPORT) -bdir $(BUILD) \
	-keep-fires \
	-aggressive-conditions \
	-show-range-conflict \
	-sim -g $(TEST_MOD) -u -D BSIM $<

sim: compile_test prep_dirs
	$(COMPILER) -sim -bdir $(BUILD) -simdir $(SIM_DIR) \
	-e $(TEST_MOD) -D BSIM -o $(TEST_MOD)Sim 

vcd: sim
	./$(TEST_MOD)Sim -V $(SIM_DIR)/dump.vcd

gtkw: vcd
	gtkwave viewMirror.gtkw

prog: $(TARGET).bit
	ecpdap program $<

# prog: $(TARGET).bit
# 	openFPGALoader -c digilent_hs2 $(TARGET).bit

clean: 
	rm -rf $(BUILD) *.sched *.svf *.bit *.config *.ys *.json $(TEST_MOD)Sim *.so