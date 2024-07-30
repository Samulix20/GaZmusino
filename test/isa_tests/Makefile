TEST_TARGET ?= base/base.S
BUILD_DIR ?= ../../build/isa_tests
BSP_DIR ?= ../../bsp

TEST_BASENAME = $(basename $(TEST_TARGET))

CROSS := riscv64-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

TEST_BUILD := $(BUILD_DIR)/$(TEST_BASENAME)

CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S\
	-Wall\
	-march=rv32i_zmmul_zicsr -mabi=ilp32\
	-fopt-info-optimized=comp_report.txt\
	-I macros -I $(BSP_DIR)/include\
	-ffreestanding -nostartfiles -T linker.lds

all: $(TEST_BUILD).dump

$(TEST_BUILD)_asm.csv: $(TEST_BUILD).elf
	python ../../tools/disassembly.py $^ > $@

$(TEST_BUILD).dump: $(TEST_BUILD).elf
	$(DUMP) -D $< > $(TEST_BUILD).dump

$(TEST_BUILD).elf: $(TEST_BUILD).o
	$(CC) $(CFLAGS) $^ -o $@

$(TEST_BUILD).o: $(TEST_BASENAME).S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $^ -o $@

clean:
	rm -rf $(BUILD_DIR)

