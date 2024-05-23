BUILD_DIR ?= build/bsp

# C Compiler definitions
CROSS := riscv32-unknown-elf-
CC := $(CROSS)gcc
DUMP := $(CROSS)objdump

CSRCS := $(shell find * -name '*.c')
ASRCS := $(shell find * -name '*.S')
OBJS := $(CSRCS:%.c=$(BUILD_DIR)/%.o) $(ASRCS:%.S=$(BUILD_DIR)/%.o)

CFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S \
	-ffreestanding \
	-Wall -Wextra -O3 \
	-march=rv32g -mabi=ilp32 -mno-div \
	-I ./include

bsp: $(OBJS) $(BUILD_DIR)/linker.lds

$(BUILD_DIR)/linker.lds:
	@mkdir -p $(@D)
	$(CC) -E -P -x c -I ./include linker.lds.in > $(BUILD_DIR)/linker.lds

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@
