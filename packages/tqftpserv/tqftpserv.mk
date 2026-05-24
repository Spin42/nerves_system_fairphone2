################################################################################
#
# tqftpserv
#
################################################################################

TQFTPSERV_VERSION = v1.1.1
TQFTPSERV_SITE = $(call github,linux-msm,tqftpserv,$(TQFTPSERV_VERSION))
TQFTPSERV_DEPENDENCIES = qrtr zstd
TQFTPSERV_LICENSE = BSD-3-Clause

$(eval $(meson-package))
