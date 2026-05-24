################################################################################
#
# Qrtr
#
################################################################################

QRTR_VERSION = ef44ad10f284410e2db4c4ce22c8645f988f8402
QRTR_SITE = $(call github,linux-msm,qrtr,$(QRTR_VERSION))
QRTR_LICENSE = BSD-3-Clause
# Required so $(STAGING_DIR)/usr/lib/pkgconfig/qrtr.pc + the libqrtr
# headers are available when tqftpserv / rmtfs configure against this
# library.
QRTR_INSTALL_STAGING = YES

$(eval $(meson-package))
