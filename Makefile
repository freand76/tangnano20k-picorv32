###
### TOOLS
###

YOSYS = yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

BUILD_DIR=out
SW_BUILD_DIR=sw_out

all: iverilog synth

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SW_BUILD_DIR)

###
### FLASH MODEL CAN BE REQUESTED/DOWNLOADED FROM WINBOND
###

SPI_FLASH_MDOEL=/projects/W25Q64JVxxIM/W25Q64JVxxIM.v

###
### COMMON FILES
###

VERILOG_FILES = \
	src/soc_top.v \
	src/picorv32.v \
	src/uart_tx.v \
	src/ram_memory.v \
	src/spi_flash_read.v

###
### VERILATOR
###

.PHONY: lint
lint:
	verilator --lint-only $(VERILOG_FILES) --top-module soc_top

###
### IVERILOG
###

IVERILOG_FILES = \
	src/iverilog_top.v \
	$(SPI_FLASH_MDOEL)

.PHONY: iverilog
iverilog: $(BUILD_DIR)/top_vvp

$(BUILD_DIR)/top_vvp: $(VERILOG_FILES) $(IVERILOG_FILES)
	mkdir -p $(BUILD_DIR)
	iverilog -g2005-sv -DIVERLOG -o $@ $^

run: $(BUILD_DIR)/top_vvp MEM.TXT
	vvp $(BUILD_DIR)/top_vvp

###
### TANGNANO20K
###

CST=tangnano20k.cst

TANGNANO20K_FILES = \
	src/tangnano20k_top.v

.PHONY: synth
synth: $(BUILD_DIR)/top_synth.json

.PHONY: pnr
pnr: $(BUILD_DIR)/top.fs

$(BUILD_DIR)/top_synth.json : $(VERILOG_FILES) $(TANGNANO20K_FILES)
	mkdir -p $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv $^ ; synth_gowin -json $@"

$(BUILD_DIR)/top_pnr.json : $(BUILD_DIR)/top_synth.json $(CST)
	mkdir -p $(BUILD_DIR)
	$(NEXTPNR) --json $< --write $@ --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=$(CST)

$(BUILD_DIR)/top.fs: $(BUILD_DIR)/top_pnr.json
	$(GOWIN_PACK) -d GW2A-18C -o $@ $<

.PHONY: program-sram-top
program-sram-top: $(BUILD_DIR)/top.fs
	openFPGALoader -btangnano20k -m $<

.PHONY: program-flash-top
program-flash-top: $(BUILD_DIR)/top.fs
	openFPGALoader -btangnano20k -f $<

###
### SOFTWARE
###

$(SW_BUILD_DIR)/start.o: sw/start.S
	mkdir -p $(SW_BUILD_DIR)
	riscv64-unknown-elf-gcc -mabi=ilp32 -march=rv32im -c -o $@ $<

SW_OBJECTS = $(SW_BUILD_DIR)/start.o

$(SW_BUILD_DIR)/fw.elf: $(SW_OBJECTS) sw/riscv.ld
	riscv64-unknown-elf-ld -b elf32-littleriscv -m elf32lriscv -static -nostdlib --strip-debug $(SW_OBJECTS) -o $@ -Tsw/riscv.ld

$(SW_BUILD_DIR)/flash_content.bin: $(SW_BUILD_DIR)/fw.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

MEM.TXT: $(SW_BUILD_DIR)/flash_content.bin
	hexdump -v -e '4/1 "%02x " "\n"' $< > $@

program-flash-code: $(SW_BUILD_DIR)/flash_content.bin
	openFPGALoader -btangnano20k --external-flash -o 0x500000 $<
