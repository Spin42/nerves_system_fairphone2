#!/bin/sh

set -e

# Create the fwup ops script to handling MicroSD/eMMC operations at runtime
# NOTE: revert.fw is the previous, more limited version of this. ops.fw is
#       backwards compatible.
mkdir -p $TARGET_DIR/usr/share/fwup
$HOST_DIR/usr/bin/fwup -c -f $NERVES_DEFCONFIG_DIR/fwup-ops.conf -o $TARGET_DIR/usr/share/fwup/ops.fw
ln -sf ops.fw $TARGET_DIR/usr/share/fwup/revert.fw

# Copy the fwup includes to the images dir
cp -rf $NERVES_DEFCONFIG_DIR/fwup_include $BINARIES_DIR

mkdir -p $BINARIES_DIR/boot/extlinux
cp $NERVES_DEFCONFIG_DIR/extlinux/extlinux.conf $BINARIES_DIR/boot/extlinux/
cp $BINARIES_DIR/zImage $BINARIES_DIR/boot/
cp $BINARIES_DIR/*.dtb $BINARIES_DIR/boot/
cp $BINARIES_DIR/rootfs.cpio $BINARIES_DIR/boot/initramfs

genext2fs -B 1024 -b 51200 -d $BINARIES_DIR/boot/ $BINARIES_DIR/boot.img