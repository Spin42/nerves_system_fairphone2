# Buildroot packages

Every package's `Config.in` title carries a scope tag indicating how
hardware-specific it is.

| Tag | Meaning |
|---|---|
| `[FP2]` | Hardware-bound to the Fairphone 2 — uses its specific firmware blobs, partition layout, or DTS nodes. Won't run on other boards. |
| `[Qualcomm generic]` | Works on any Qualcomm SoC that ships the relevant kernel subsystem (QRTR, remoteproc, ADSP). Useful on FP2, FP3, dragonboard, etc. |
| `[Generic]` | No hardware dependency. Could move upstream to `nerves_system_br`. |

## Current packages

| Package | Tag | Notes |
|---|---|---|
| `fp2-firmware` | `[FP2]` | Proprietary blobs (modem, ADSP, WCNSS, Venus) from FairBlobs/FP2-firmware, plus the committed ADSP sensor registry `qcom/sensors/sns.reg`. |
| `citronics-initramfs` | `[FP2]` | Recovery initramfs built from source — board-specific partition layout (`kpartx /dev/mmcblk0p20`) and USB DHCP recovery. |
| `qrtr` | `[Qualcomm generic]` | Userspace reference for net/qrtr (IPC Router); provides `libqrtr`. |
| `rmtfs` | `[Qualcomm generic]` | Remote filesystem service backing the modem / ADSP EFS over QRTR. |
| `tqftpserv` | `[Qualcomm generic]` | TFTP-like server that ships firmware files to remoteprocs over QRTR. |
| `hexagonrpc` | `[Qualcomm generic]` | FastRPC userspace (`hexagonrpcd`, `chrecd`, `libhexagonrpc`) — serves the DSP shell/libs to the ADSP. |
| `reboot-mode` | `[Qualcomm generic]` | Reboots into `bootloader`/`recovery`/`edl` via `LINUX_REBOOT_CMD_RESTART2`. |
| `unudhcpd` | `[Generic]` | Tiny single-IP DHCP server. Used by the recovery initramfs. |

The userspace bring-up these binaries need (start order, ADSP/modem
remoteproc boot, HexagonFS population) lives in small OTP applications
in the consuming Nerves app — see the top-level README — not in
`/etc/init.d/Sxx` scripts.

## Adding a package

Pick the most restrictive tag that still applies:
- If the code references FP2-specific firmware/partitions/DTS → `[FP2]`.
- If it talks to a generic Qualcomm kernel subsystem → `[Qualcomm generic]`.
- If it has no hardware assumption → `[Generic]`, and consider whether
  it belongs upstream in `nerves_system_br` instead of here.

The `[Qualcomm generic]` set is shared almost verbatim with
`nerves_system_fp3`; long-term it's a candidate for a common parent
`nerves_system_qcom` once the two boards want to share more.
