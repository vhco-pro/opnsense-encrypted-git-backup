PLUGIN_NAME=		encrypted-git-backup
PLUGIN_VERSION=		0.1
PLUGIN_COMMENT=		Back up encrypted configurations over Git and SSH
PLUGIN_DEPENDS=		git openssh-portable
PLUGIN_MAINTAINER=	VH & Co BV
PLUGIN_WWW=		https://github.com/vhco-pro/opnsense-encrypted-git-backup
PLUGIN_TIER=		3

.include "../../Mk/plugins.mk"
