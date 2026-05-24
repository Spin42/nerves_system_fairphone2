################################################################################
#
# hexagonrpc
#
################################################################################

HEXAGONRPC_VERSION = v0.4.0
HEXAGONRPC_SITE = $(call github,linux-msm,hexagonrpc,$(HEXAGONRPC_VERSION))
HEXAGONRPC_LICENSE = GPL-3.0
HEXAGONRPC_INSTALL_STAGING = YES

HEXAGONRPC_CONF_OPTS = -Dhexagonrpcd_verbose=true

$(eval $(meson-package))
