#!/bin/sh

set -e

$NERVES_DEFCONFIG_DIR/scripts/create-boot-img.sh

# U-Boot as an Android boot image for the boot partition. LK loads it at
# 0x8000 and copies the device tree appended to u-boot.bin to 0x01e00000.
python3 $NERVES_DEFCONFIG_DIR/scripts/mkbootimg.py \
    --kernel $BINARIES_DIR/u-boot.bin \
    --output $BINARIES_DIR/u-boot-fp2.img

FWUP_CONFIG=$NERVES_DEFCONFIG_DIR/fwup.conf

# Run the common post-image processing for nerves
$BR2_EXTERNAL_NERVES_PATH/board/nerves-common/post-createfs.sh $TARGET_DIR $FWUP_CONFIG
