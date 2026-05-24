################################################################################
#
# citronics-initramfs (Nerves-flavoured, Fairphone 2 / msm8974, armv7)
#
# This replaces the old "citros-initramfs" package, which downloaded a single
# prebuilt initramfs-citros-<tag>.cpio.gz with kernel modules baked in for one
# fixed kernel build. That hardwired image broke whenever the kernel moved,
# because the baked-in /lib/modules/<ver> no longer matched the running kernel.
#
# Here we BUILD the initramfs from the upstream Citronics init scripts and
# populate it at buildroot time: the kernel version is detected from the
# freshly-built modules tree, the few non-busybox helpers are copied together
# with their shared-library closure, and the Adreno GPU firmware is baked in.
# Mirrors the nerves_system_fp3 package; source paths live under
# $(NERVES_DEFCONFIG_DIR), deviceinfo + modules list ship inside this package.
#
################################################################################

CITRONICS_INITRAMFS_VERSION = 6e058d7
CITRONICS_INITRAMFS_SITE = https://github.com/Citronics/initramfs.git
CITRONICS_INITRAMFS_SITE_METHOD = git
CITRONICS_INITRAMFS_LICENSE_FILES = LICENSE

CITRONICS_INITRAMFS_DEPENDENCIES = busybox unudhcpd multipath-tools parted

CITRONICS_INITRAMFS_STAGING = $(@D)/initramfs-root
CITRONICS_INITRAMFS_SRC_DIR = initramfs/usr/share/citronics-initramfs
CITRONICS_INITRAMFS_PKG_DIR = $(NERVES_DEFCONFIG_DIR)/packages/citronics-initramfs
# Only the non-busybox programs the upstream init/functions.sh actually
# invoke: kpartx (subpartition mapping), parted (resize_rootfs path,
# optional), unudhcpd (USB-recovery DHCP). Everything else — udevd,
# dmsetup, resize2fs, blkid, sfdisk, lsblk, partprobe, kmod, e2fsck —
# is provided by busybox or simply not called, and was previously
# bloating the cpio.gz past lk2nd's max-initrd ceiling.
CITRONICS_BINARIES = busybox kpartx parted unudhcpd

KERNEL_VERSION = $(shell find $(TARGET_DIR)/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | head -n1)

define CITRONICS_INITRAMFS_BUILD_CMDS
	true
endef

define CITRONICS_INITRAMFS_INSTALL_TARGET_CMDS
	mkdir -p $(CITRONICS_INITRAMFS_STAGING)
	mkdir -p $(CITRONICS_INITRAMFS_STAGING)/{bin,sbin,usr/bin,usr/sbin,lib,etc,proc,sys,dev,tmp,var,run,mnt,root,sysroot}
	chmod 1777 $(CITRONICS_INITRAMFS_STAGING)/tmp
	chmod 1777 $(CITRONICS_INITRAMFS_STAGING)/run

	# Mirror the buildroot target's lib64 -> lib symlinks. On armv7 the
	# dynamic loader (ld-linux-armhf.so.3) lives in /lib and nothing looks
	# in /lib64, so these are no-ops here — but they're harmless and keep
	# the initramfs builder identical to the aarch64 sibling system, where
	# ld.so's compiled-in trusted search paths *are* /lib64 + /usr/lib64.
	ln -sf lib $(CITRONICS_INITRAMFS_STAGING)/lib64
	ln -sf lib $(CITRONICS_INITRAMFS_STAGING)/usr/lib64

	# Copy the citronics-initramfs scripts into the initramfs root.
	cp -aL $(@D)/$(CITRONICS_INITRAMFS_SRC_DIR)/* $(CITRONICS_INITRAMFS_STAGING)/
	mkdir -p $(CITRONICS_INITRAMFS_STAGING)/usr/share/deviceinfo
	cp -RaL $(CITRONICS_INITRAMFS_STAGING)/misc $(CITRONICS_INITRAMFS_STAGING)/usr/share/misc
	# This Nerves system carries deviceinfo inside the package directory —
	# there is no buildroot board overlay to inherit from.
	$(INSTALL) -D -m 0644 $(CITRONICS_INITRAMFS_PKG_DIR)/deviceinfo \
		$(CITRONICS_INITRAMFS_STAGING)/usr/share/deviceinfo/deviceinfo

	# Drop the upstream initramfs.load module list. On this kernel the
	# rootfs / dm / usb-gadget drivers the initramfs needs are all built-in
	# (=y), so there is nothing to modprobe before pivot_root; an out-of-date
	# load list only produces noisy modprobe failures.
	: > $(CITRONICS_INITRAMFS_STAGING)/lib/modules/initramfs.load

	mkdir -p $(CITRONICS_INITRAMFS_STAGING)/lib/modules/$(KERNEL_VERSION)
	@echo "Detected kernel version: $(KERNEL_VERSION)"
	@echo "Copying kernel modules listed in $(CITRONICS_INITRAMFS_PKG_DIR)/modules..."

	while read -r modpath; do \
		case "$$modpath" in ""|\#*) continue;; esac; \
		src="$(TARGET_DIR)/lib/modules/$(KERNEL_VERSION)/$$modpath"; \
		dest="$(CITRONICS_INITRAMFS_STAGING)/lib/modules/$(KERNEL_VERSION)/$$modpath"; \
		if [ -f "$$src" ]; then \
			mkdir -p "$$(dirname "$$dest")"; \
			cp -aL "$$src" "$$dest"; \
		else \
			echo "  warn: module $$modpath not present in target — skipping"; \
		fi; \
	done < $(CITRONICS_INITRAMFS_PKG_DIR)/modules

	@echo "Copying required binaries from target to initramfs..."
	for bin in $(CITRONICS_BINARIES); do \
		src=""; \
		for dir in usr/sbin sbin usr/bin bin; do \
			candidate="$(TARGET_DIR)/$$dir/$$bin"; \
			if [ -x "$$candidate" ]; then \
				src="$$candidate"; \
				break; \
			fi; \
		done; \
		if [ -z "$$src" ]; then \
			echo "  warn: binary $$bin not found in target"; \
		else \
			relpath=$$(realpath --relative-to=$(TARGET_DIR) $$src); \
			dest="$(CITRONICS_INITRAMFS_STAGING)/$$relpath"; \
			mkdir -p "$$(dirname $$dest)"; \
			cp -aL "$$src" "$$dest"; \
			$(CITRONICS_INITRAMFS_PKG_DIR)/scripts/copy_libs_for_binary.sh \
				$$src $(TARGET_DIR) $(CITRONICS_INITRAMFS_STAGING) $(TARGET_READELF) ; \
		fi; \
	done

	cd $(CITRONICS_INITRAMFS_STAGING)/bin && \
		ln -sf busybox sh && \
		ln -sf busybox telnetd && \
		ln -sf busybox getty

	# Bake the Adreno GPU firmware into the initramfs. The in-tree msm DRM
	# driver probes the GPU early — BEFORE pivot_root from the initramfs into
	# the rootfs — and adreno_request_fw() uses request_firmware_direct()
	# (no wait, no retry), so if the files aren't visible at probe time the
	# GPU is dead for the rest of the boot. The Fairphone 2's Adreno 330 is
	# a3xx (a330_pm4.fw / a330_pfp.fw / a300_zap.*); the patterns below are
	# generic across Adreno generations so the same rule serves a5xx/a6xx
	# siblings too. Modem / ADSP / WCNSS / Venus blobs are deliberately
	# skipped — those load via remoteproc after pivot_root.
	if [ -d "$(TARGET_DIR)/lib/firmware/qcom" ]; then \
		mkdir -p "$(CITRONICS_INITRAMFS_STAGING)/lib/firmware/qcom"; \
		cd "$(TARGET_DIR)/lib/firmware/qcom" && \
		find . \( -name 'a*_pm4.fw*' \
		       -o -name 'a*_pfp.fw*' \
		       -o -name 'a*_sqe.fw*' \
		       -o -name 'a*_gpmu.fw*' \
		       -o -name 'a*_gmu.bin' \
		       -o -name 'a*_zap.mdt' \
		       -o -name 'a*_zap.mbn' \
		       -o -name 'a*_zap.elf' \
		       -o -name 'a*_zap.b*' \) -print | \
		while read f; do \
			dest="$(CITRONICS_INITRAMFS_STAGING)/lib/firmware/qcom/$$f"; \
			mkdir -p "$$(dirname "$$dest")"; \
			cp -aL "$$f" "$$dest"; \
		done; \
	fi

	# The upstream init uses busybox's `mdev` for device-node hotplug, not
	# full udev — so we deliberately do not copy /usr/lib/udev. Pulling it in
	# dragged in ~19 MiB of libcrypto via udev's dependency chain, blowing
	# past lk2nd's initrd size limit.

	# CPIO -> gzip; nerves-common's post-createfs pipeline / create-boot-img.sh
	# pick the resulting initramfs.gz out of $(BINARIES_DIR).
	(cd $(CITRONICS_INITRAMFS_STAGING) && \
		find . | cpio -o -H newc --owner root:root > ../initramfs.cpio)
	gzip -f $(@D)/initramfs.cpio
	cp $(@D)/initramfs.cpio.gz $(BINARIES_DIR)/initramfs.gz
endef

$(eval $(generic-package))
