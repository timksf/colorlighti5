
# filenames
TARGET_NAME=Blinky
TOP=Blinky
MOD_NAME=mk$(TOP)
TEST_NAME=Testbench
TEST_MOD=mk$(TEST_NAME)

# directories
REPORTS=reports
BUILD=build
VERILOG=$(BUILD)/verilog
VERILOG_TOP=$(VERILOG)/$(MOD_NAME).v
SIM=$(BUILD)/sim

TARGET=$(BUILD)/$(TARGET_NAME)

COMMON=../common/

BLUEIMPORT=.:$(COMMON):+

COMPILER=bsc
TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

prep_dirs:
	@mkdir -p $(BUILD)
	@mkdir -p $(VERILOG)
	@mkdir -p $(SIM)
	@mkdir -p $(REPORTS)

compile: $(TOP).bsv prep_dirs
	$(COMPILER) -bdir $(BUILD) -p $(BLUEIMPORT) -sim -g $(MOD_NAME) -u $<
	$(CLEAR)

gen_verilog: $(TOP).bsv	prep_dirs
	$(COMPILER) -bdir $(BUILD) -p $(BLUEIMPORT) -remove-dollar -u -verilog -vdir $(VERILOG) -g $(MOD_NAME) $<
	@echo "\n\`include \"$(COMMON)lib_imports.v\"" >> $(VERILOG_TOP)	

$(TARGET).json: gen_verilog 
	yosys -p "read_verilog $(VERILOG_TOP); tee -o $(REPORTS)/synthesis_report.txt synth_ecp5 -top $(MOD_NAME) -json $@" 
	
$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 \
		--25k \
		--package CABGA381 \
		--speed 6 \
		--json $<\
		--textcfg $@\
		--lpf $(TARGET_NAME).lpf\
		--freq 65 \
		--report $(REPORTS)/pnr_report.json \
		--log $(REPORTS)/pnr_log.txt

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf $(TARGET).svf $< $@

${TARGET}.svf : ${TARGET}.bit

compile_test: $(TEST_NAME).bsv prep_dirs
	$(COMPILER) -p $(BLUEIMPORT) -bdir $(BUILD) -sim -g $(TEST_MOD) -u -D BSIM $<

sim: compile_test prep_dirs
	$(COMPILER) -bdir $(BUILD) -simdir $(SIM) -sim -e $(TEST_MOD) -D BSIM -o $(TEST_MOD)Sim 

vcd: sim
	./$(TEST_MOD)Sim -V $(SIM)/dump.vcd

clean: 
	rm -rf $(BUILD) *.svf *.bit *.config *.ys *.json $(TEST_MOD)Sim *.so $(REPORTS)