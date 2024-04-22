TEST_TARGET ?= base/base
BUILD_DIR ?= ../build

CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

TEST_BUILD := $(BUILD_DIR)/$(TEST_TARGET)

CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S\
	-Wall\
	-march=rv32g -mabi=ilp32 -mno-div\
	-fopt-info-optimized=comp_report.txt\
	-I macros\
	-ffreestanding -nostartfiles -T linker.lds

all: clean $(TEST_BUILD).dump

$(TEST_BUILD).dump: $(TEST_BUILD).elf
	$(DUMP) -D $< > $(TEST_BUILD).dump

$(TEST_BUILD).elf: $(TEST_BUILD).o
	$(CC) $(CFLAGS) $^ -o $@

$(TEST_BUILD).o: $(TEST_TARGET).S
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $^ -o $@

clean:
	rm -rf $(BUILD_DIR)

