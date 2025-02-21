#!/bin/sh

set -e

# Create boot partition image
mkdir -p $BINARIES_DIR/boot/extlinux
cp $NERVES_DEFCONFIG_DIR/extlinux/extlinux.conf $BINARIES_DIR/boot/extlinux/
cp $BINARIES_DIR/zImage $BINARIES_DIR/boot/
cp $BINARIES_DIR/*.dtb $BINARIES_DIR/boot/

#echo "Create cpio temp folder..."
mkdir -p $BINARIES_DIR/temp_cpio && cd $BINARIES_DIR/temp_cpio
zcat $BINARIES_DIR/initramfs | fakeroot cpio -idm
#echo "Remove uneeded firmware files..."
#rm -r ./lib/firmware
#rm -r ./lib/modules/6.11.4/kernel/net
#rm -r ./lib/modules/6.11.4/kernel/sound
#rm -r ./lib/modules/6.11.4/kernel/drivers/net
#rm -r ./lib/modules/6.11.4/kernel/drivers/bluetooth
#rm ./usr/sbin/wpa_supplicant
#rm -r ./usr/lib/locale
#rm ./usr/bin/bluetoothctl
#rm ./usr/bin/bt*
#rm -r ./etc/udev
#mkdir -p lib/firmware
#echo "Copy relevant qcom firmware to initramfs..."
#cp $TARGET_DIR/lib/firmware/qcom/a3* lib/firmware/
#echo "Copy initramfs_overlay..."
#cp -r $NERVES_DEFCONFIG_DIR/initramfs_overlay/* .
#echo "Repackage the initramfs and gzip it..."
#mkdir -p bin dev etc lib mnt proc sbin sys tmp var
#cp $TARGET_DIR/bin/* ./bin/
#cp $TARGET_DIR/sbin/* ./sbin/
#cp $TARGET_DIR/lib/firmware/qcom/a3* $BINARIES_DIR/boot/
#fakeroot mknod -m 622 ./dev/console c 5 1
#fakeroot mknod -m 666 ./dev/null c 1 3
#cp -r $NERVES_DEFCONFIG_DIR/initramfs_overlay/* ./
#chmod +x ./init

find . | cpio -o -H newc | gzip -c > ../initramfs.gz
cd $BINARIES_DIR

cp $BINARIES_DIR/initramfs.gz $BINARIES_DIR/boot/initramfs.gz

genext2fs -B 1024 -b 51200 -d $BINARIES_DIR/boot/ $BINARIES_DIR/boot.img
