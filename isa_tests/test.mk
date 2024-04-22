TARGET_TEST ?= base
BUILD_DIR := build

all:
	make -f bsp/rvc.mk \
	INPUT_ASRCS=isa_tests/base/base.S \
	TARGET_NAME=base \
	INCLUDE_DIRS="-I isa_tests/macros" \
	LDS_SCRIPT= \

