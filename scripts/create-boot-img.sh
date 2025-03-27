#!/bin/sh

set -e

# Create boot partition image
mkdir -p $BINARIES_DIR/boot/extlinux
cp $NERVES_DEFCONFIG_DIR/extlinux/extlinux.conf $BINARIES_DIR/boot/extlinux/
cp $BINARIES_DIR/zImage $BINARIES_DIR/boot/
cp $BINARIES_DIR/*.dtb $BINARIES_DIR/boot/
cp $BINARIES_DIR/initramfs.gz $BINARIES_DIR/boot/

genext2fs -B 1024 -b 51200 -d $BINARIES_DIR/boot/ $BINARIES_DIR/boot.img
