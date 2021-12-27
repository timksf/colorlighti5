TARGET=Top
TOP=Top
MOD_NAME=mk$(TOP)

COMPILER=bsc

BUILD=build
VERILOG=$(BUILD)/verilog

TRELLIS=/usr/local/share/trellis

all: ${TARGET}.bit

prep_dirs:
	@mkdir -p $(BUILD)
	@mkdir -p $(VERILOG)

compile: $(TOP).bsv prep_dirs
	$(COMPILER) -bdir $(BUILD) -sim -g $(MOD_NAME) -u $<
	$(CLEAR)

gen_verilog: $(TOP).bsv	prep_dirs
	$(COMPILER) -bdir $(BUILD) -remove-dollar -u -verilog -vdir $(VERILOG) -g $(MOD_NAME) $<

# find_verilog : gen_verilog
# 	@echo $(shell find $(VERILOG) -type f -name "*.v")

$(TARGET).json: gen_verilog 
	yosys -p "read_verilog $(VERILOG)/$(MOD_NAME).v; synth_ecp5 -json $@" $(shell find $(VERILOG) -type f -name "*.v")

# $(shell find $(VERILOG) -type f -name "*.v")

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --25k --package CABGA381 --speed 6 --json $< --textcfg $@ --lpf $(TARGET).lpf --freq 65

$(TARGET).bit: $(TARGET)_out.config
	ecppack --svf $(TARGET).svf $< $@

${TARGET}.svf : ${TARGET}.bit


# prog: $(TARGET).bit
# 	openFPGALoader -b colorlight_i5 $(TARGET).bit

clean: 
	rm -rf $(BUILD) *.svf *.bit *.config *.ys *.json