TEST_TARGET ?= base/base.S
BUILD_DIR ?= ../build
BSP_DIR ?= ../bsp

TEST_BASENAME = $(basename $(TEST_TARGET))

CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

TEST_BUILD := $(BUILD_DIR)/$(TEST_BASENAME)

CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S\
	-Wall\
	-march=rv32g -mabi=ilp32 -mno-div\
	-fopt-info-optimized=comp_report.txt\
	-I macros -I $(BSP_DIR)\
	-ffreestanding -nostartfiles -T linker.lds

all: clean $(TEST_BUILD).dump

$(TEST_BUILD).dump: $(TEST_BUILD).elf
	$(DUMP) -D $< > $(TEST_BUILD).dump

$(TEST_BUILD).elf: $(TEST_BUILD).o
	$(CC) $(CFLAGS) $^ -o $@

$(TEST_BUILD).o: $(TEST_BASENAME).S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $^ -o $@

clean:
	rm -rf $(BUILD_DIR)

