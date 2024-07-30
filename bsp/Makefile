# Makefile for compilation of C/C++ programs for RISC-V platform
SRCS ?=
BUILD_DIR ?=
BSP_DIR ?=
EXTRA_FLAGS ?=

# Setup BSP build subdir
BSP_BUILD_DIR := $(BUILD_DIR)/bsp

include $(BSP_DIR)/Target.mk

# BSP must be compiled before
BSP_OBJS := $(shell find $(BSP_BUILD_DIR) -name '*.o')

$(BUILD_DIR)/main.dump: $(BUILD_DIR)/main.elf
	@mkdir -p $(@D)
	$(DUMP) -D $< > $(BUILD_DIR)/main.dump

$(BUILD_DIR)/main.elf: $(OBJS) $(BSP_OBJS)
	@mkdir -p $(@D)
	$(LN) $^ -o $@

# Basic build C/C++ build rules
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@
