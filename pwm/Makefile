
# filenames
TARGET_NAME=PWMGen
TOP=PWMGen
MOD_NAME=mk$(TOP)
TEST_NAME=Testbench
TEST_MOD=mk$(TEST_NAME)

# directories
BUILD=build
VERILOG=$(BUILD)/verilog
SIM=$(BUILD)/sim

TARGET=$(BUILD)/$(TARGET_NAME)

COMMON=../common/

BLUEROOT=$(shell bsc --help | grep "Bluespec directory: " | awk '{print $$3}')
BLUELIB=$(BLUEROOT)/Libraries
BLUEIMPORT=.:$(BLUELIB):$(COMMON)

COMPILER=bsc
TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

prep_dirs:
	@mkdir -p $(BUILD)
	@mkdir -p $(VERILOG)
	@mkdir -p $(SIM)

compile: $(TOP).bsv prep_dirs
	$(COMPILER) -bdir $(BUILD) -p $(BLUEIMPORT) -sim -g $(MOD_NAME) -u $<
	$(CLEAR)

gen_verilog: $(TOP).bsv	prep_dirs
	$(COMPILER) -bdir $(BUILD) -p $(BLUEIMPORT) -remove-dollar -u -verilog -vdir $(VERILOG) -g $(MOD_NAME) $<

$(TARGET).json: gen_verilog 
	yosys -p "read_verilog $(VERILOG)/$(MOD_NAME).v; synth_ecp5 -json $@" $(shell find $(VERILOG) -type f -name "*.v")

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --25k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf $(TARGET_NAME).lpf --freq 65

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf $(TARGET).svf $< $@

${TARGET}.svf : ${TARGET}.bit

compile_test: $(TEST_NAME).bsv prep_dirs
	$(COMPILER) -p $(BLUEIMPORT) -bdir $(BUILD) -sim -g $(TEST_MOD) -u -D BSIM $<

sim: compile_test prep_dirs
	$(COMPILER) -bdir $(BUILD) -simdir $(SIM) -sim -e $(TEST_MOD) -D BSIM -o $(TEST_MOD)Sim 

vcd: sim
	./$(TEST_MOD)Sim -V $(SIM)/dump.vcd

# prog: $(TARGET).bit
# 	openFPGALoader -c digilent_hs2 $(TARGET).bit

clean: 
	rm -rf $(BUILD) *.svf *.bit *.config *.ys *.json $(TEST_MOD)Sim *.so