# Params
SRCS ?= 			# Source file list
BUILD_DIR ?=		# Build directory
BSP_DIR ?=			# BSP directory
BSP_BUILD_DIR ?=	# BSP build directory (only required for linking)
EXTRA_FLAGS ?=		# Optional extra flags

# Cross Compiler definitions
CROSS := riscv64-unknown-elf-
CC := $(CROSS)gcc
CXX := $(CROSS)g++
DUMP := $(CROSS)objdump

# Compiler flags
OPTFLAGS := \
	-fdata-sections -ffunction-sections -Wl,--gc-sections,-S \
	-Wall -Wextra -O3 \
	-fopt-info-optimized=$(BUILD_DIR)/comp_report.txt
ARCHFLAGS := -march=rv32i_zmmul_zicsr -mabi=ilp32
BSPFLAGS := -I $(BSP_DIR)/include -T $(BSP_BUILD_DIR)/linker.lds

CFLAGS := $(OPTFLAGS) $(ARCHFLAGS) $(BSPFLAGS) $(EXTRA_FLAGS)
CXXFLAGS := $(CFLAGS) -fno-exceptions -fno-unwind-tables -fno-rtti

# Set Source objects
ASRCS := $(filter %.S, $(SRCS))
CSRCS := $(filter %.c, $(SRCS))
CPPSRCS := $(filter %.cc %.cpp, $(SRCS))
OBJS := \
	$(CPPSRCS:%.cpp=$(BUILD_DIR)/%.o) \
	$(CSRCS:%.c=$(BUILD_DIR)/%.o) \
	$(ASRCS:%.S=$(BUILD_DIR)/%.o)

# If cpp sources present, target is cpp
ifeq ($(CPPSRCS),)
LN := $(CC) $(CFLAGS)
else
LN := $(CXX) $(CXXFLAGS)
endif

