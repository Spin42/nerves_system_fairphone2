################################################################################
#
# INITRAMFS_BUILDROOT
#
################################################################################

INITRAMFS_BUILDROOT_VERSION = v0.1
INITRAMFS_BUILDROOT_SITE = https://github.com/Spin42/initramfs-buildroot/releases/download/$(INITRAMFS_BUILDROOT_VERSION)
INITRAMFS_BUILDROOT_LICENSE = MIT
INITRAMFS_BUILDROOT_INSTALL_IMAGES = YES

define INITRAMFS_BUILDROOT_BUILD_CMDS
    tar -xzf $(INITRAMFS_BUILDROOT_DL_DIR)/initramfs-buildroot-$(INITRAMFS_BUILDROOT_VERSION).tar.gz -C $(@D)
endef

define INITRAMFS_BUILDROOT_INSTALL_TARGET_CMDS
    mkdir -p $(BINARIES_DIR)/initramfs/
    $(INSTALL) -D $(@D)/* $(BINARIES_DIR)/initramfs/
endef

$(eval $(generic-package))
