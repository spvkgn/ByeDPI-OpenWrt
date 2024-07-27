include $(TOPDIR)/rules.mk

PKG_NAME:=byedpi
PKG_RELEASE:=1

PKG_SOURCE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/hufrea/byedpi/archive/
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/byedpi
	SECTION:=net
	CATEGORY:=Network
	TITLE:=ByeDPI
	URL:=https://github.com/hufrea/byedpi
endef

define Package/byedpi/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ciadpi $(1)/usr/bin

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/byedpi.init $(1)/etc/init.d/byedpi

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/byedpi.config $(1)/etc/config/byedpi

	$(INSTALL_DIR) $(1)/usr/share/byedpi
	echo "$(PKG_VERSION)-$(PKG_RELEASE)" > $(1)/usr/share/byedpi/version
endef

$(eval $(call BuildPackage,byedpi))
