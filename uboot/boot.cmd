# Nerves boot script, sourced by U-Boot from the first partition of the image
# in userdata (blkmap device ${ud_dev}). fwup swaps the MBR on every update so
# that this partition is always the active boot partition (A or B), and the
# second one is the matching root filesystem.
#
# U-Boot environment variables that change the boot (setenv ...; saveenv):
#   fp2_dtb   device tree to boot. By default the phone's,
#             qcom-msm8974pro-fairphone-fp2.dtb, or, when LK lit no panel
#             (headless, e.g. a mainboard on a carrier such as the Citronics
#             Lime), qcom-msm8974pro-fairphone-fp2-rig.dtb
#   usb_mode  "host" makes Linux a USB host regardless of the ID line

if test -z "${fp2_dtb}"; then
	if test -n "${headless}"; then
		setenv fp2_dtb qcom-msm8974pro-fairphone-fp2-rig.dtb
	else
		setenv fp2_dtb qcom-msm8974pro-fairphone-fp2.dtb
	fi
fi

load blkmap ${ud_dev}:1 ${kernel_addr_r} /zImage
load blkmap ${ud_dev}:1 ${fdt_addr_r} /${fp2_dtb}
load blkmap ${ud_dev}:1 ${ramdisk_addr_r} /initramfs.gz
setenv ramdisk_size ${filesize}

if test "${usb_mode}" = host; then
	fdt addr ${fdt_addr_r}
	fdt resize
	fdt set /soc/usb@f9a55000 dr_mode host
fi

setenv bootargs "earlycon=msm_serial_dm,0xf991e000 msm.vram=192m msm.allow_vram_carveout=1 fbcon=rotate:1 fbcon=font:TER16x32 rootfs=/dev/mmcblk0p20p2 bootpart=/dev/mmcblk0p20p1"
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${ramdisk_size} ${fdt_addr_r}
