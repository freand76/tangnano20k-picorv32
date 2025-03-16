###
### TOOLS
###

YOSYS = yosys
NEXTPNR = nextpnr-himbaechel
GOWIN_PACK = gowin_pack

RTL_BUILD_DIR=rtl_out
SW_BUILD_DIR=sw_out

all: iverilog synth

clean:
	rm -rf $(RTL_BUILD_DIR)
	rm -rf $(SW_BUILD_DIR)

###
### FLASH MODEL CAN BE REQUESTED/DOWNLOADED FROM WINBOND
###

SPI_FLASH_MODEL=/projects/W25Q64JVxxIM/W25Q64JVxxIM.v

###
### COMMON FILES
###

VERILOG_FILES = \
	rtl/soc_top.v \
	rtl/picorv32.v \
	rtl/uart_tx.v \
	rtl/ram_memory.v \
	rtl/spi_flash_read.v

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
	rtl/iverilog_top.v \
	$(SPI_FLASH_MODEL)

.PHONY: iverilog
iverilog: $(RTL_BUILD_DIR)/top_vvp

$(RTL_BUILD_DIR)/top_vvp: $(VERILOG_FILES) $(IVERILOG_FILES)
	mkdir -p $(RTL_BUILD_DIR)
	iverilog -g2005-sv -DIVERLOG -o $@ $^

run: $(RTL_BUILD_DIR)/top_vvp MEM.TXT
	vvp $(RTL_BUILD_DIR)/top_vvp

###
### TANGNANO20K
###

CST=tangnano20k.cst

TANGNANO20K_FILES = \
	rtl/tangnano20k_top.v

.PHONY: synth
synth: $(RTL_BUILD_DIR)/top_synth.json

.PHONY: pnr
pnr: $(RTL_BUILD_DIR)/top.fs

$(RTL_BUILD_DIR)/top_synth.json : $(VERILOG_FILES) $(TANGNANO20K_FILES)
	mkdir -p $(RTL_BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv $^ ; synth_gowin -json $@"

$(RTL_BUILD_DIR)/top_pnr.json : $(RTL_BUILD_DIR)/top_synth.json $(CST)
	mkdir -p $(RTL_BUILD_DIR)
	$(NEXTPNR) --json $< --write $@ --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=$(CST)

$(RTL_BUILD_DIR)/top.fs: $(RTL_BUILD_DIR)/top_pnr.json
	$(GOWIN_PACK) -d GW2A-18C -o $@ $<

.PHONY: program-sram-top
program-sram-top: $(RTL_BUILD_DIR)/top.fs
	openFPGALoader -btangnano20k -m $<

.PHONY: program-flash-top
program-flash-top: $(RTL_BUILD_DIR)/top.fs
	openFPGALoader -btangnano20k -f $<

###
### SOFTWARE
###

CFLAGS = \
	-pedantic -Wall -Werror -Wextra \
	-Wdouble-promotion -Wstrict-prototypes -Wcast-qual \
	-Wmissing-prototypes -Winit-self -Wpointer-arith -Wshadow -MMD -MP -O3 \
	-fno-var-tracking-assignments -ffunction-sections -fdata-sections

.PHONY: software
software: $(SW_BUILD_DIR)/flash_content.bin

$(SW_BUILD_DIR)/start.o: sw/start.S
	mkdir -p $(SW_BUILD_DIR)
	riscv64-unknown-elf-gcc -mabi=ilp32 -march=rv32im -c -o $@ $<

$(SW_BUILD_DIR)/%.o: sw/%.c
	mkdir -p $(SW_BUILD_DIR)
	riscv64-unknown-elf-gcc $(CFLAGS) -mabi=ilp32 -march=rv32im -c -o $@ $<

SW_OBJECTS = \
	$(SW_BUILD_DIR)/start.o \
	$(SW_BUILD_DIR)/led_drv.o \
	$(SW_BUILD_DIR)/uart_drv.o \
	$(SW_BUILD_DIR)/test.o

$(SW_BUILD_DIR)/fw.elf: $(SW_OBJECTS) sw/riscv.ld
	riscv64-unknown-elf-ld -b elf32-littleriscv -m elf32lriscv -static -nostdlib --strip-debug $(SW_OBJECTS) -o $@ -Tsw/riscv.ld

$(SW_BUILD_DIR)/flash_content.bin: $(SW_BUILD_DIR)/fw.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

MEM.TXT: $(SW_BUILD_DIR)/flash_content.bin
	hexdump -v -e '4/1 "%02x " "\n"' $< > $@

flash-software: $(SW_BUILD_DIR)/flash_content.bin
	openFPGALoader -btangnano20k --external-flash -o 0x500000 $<

.PHONY: clang-format
clang-format:
	clang-format -i sw/*.c sw/*.h
	git status
