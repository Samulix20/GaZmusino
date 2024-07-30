# Makefile for the RISC-V platform BSP
BUILD_DIR ?= 

BSP_DIR := $(shell dirname $(realpath $(MAKEFILE_LIST)))
SRCS := $(shell find $(BSP_DIR) -name '*.c') $(shell find $(BSP_DIR) -name '*.S')

include $(BSP_DIR)/Target.mk

bsp: $(OBJS) $(BUILD_DIR)/linker.lds

$(BUILD_DIR)/linker.lds:
	@mkdir -p $(@D)
	$(CC) -E -P -x c -I $(BSP_DIR)/include $(BSP_DIR)/linker.lds.in > $(BUILD_DIR)/linker.lds

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
