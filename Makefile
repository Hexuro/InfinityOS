ASM=nasm
CC=gcc
CC16=/usr/bin/watcom/binl64/wcc
LD16=/usr/bin/watcom/binl64/wlink

SRC_DIR=source
TOOLS_DIR=tools
BUILD_DIR=build
TEST_DIR=test

.PHONY: all floppy_image kernel bootloader clean always tools_fat iso run

all: floppy_image tools_fat

#
# Floppy image
#
floppy_image: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "INFINITYOS" $(BUILD_DIR)/main_floppy.img # Check for overflow
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(TEST_DIR)/test.txt "::test.txt"
	mmd -i $(BUILD_DIR)/main_floppy.img "::mydir"
	mcopy -i $(BUILD_DIR)/main_floppy.img $(TEST_DIR)/test.txt "::mydir/test.txt"

#
# Bootloader
#
bootloader: stage1 stage2

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Tools
#
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(MAKE) -C tools/fat BUILD_DIR=$(abspath $(BUILD_DIR))

#
# Create ISO image
#
iso: $(BUILD_DIR)/mybootcd.iso

$(BUILD_DIR)/mybootcd.iso: $(BUILD_DIR)/main_floppy.img
	mkisofs -o $(BUILD_DIR)/main_bootcd.iso -V InfinityOS -b main_floppy.img $(BUILD_DIR)

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Clean
#
clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)/*

#
# Run
#
run:
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img
