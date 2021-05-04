# Comment out $THEOS/vendor/dm.pl:80 if you want to run "make package"
PACKAGE_VERSION = 1.1.1

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = Divisé

Divisé_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"' IPHONEOS_DEPLOYMENT_TARGET=11
Divisé_CODESIGN_FLAGS = -SEntitlements.plist

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS = succdatroot

after-stage::
	ldid -SEntitlements.plist $(THEOS_STAGING_DIR)/Applications/Divisé.app/Divisé
	ldid -SEntitlements.plist $(THEOS_STAGING_DIR)/Applications/Divisé.app/apfs_deletefs
	ldid -SEntitlements.plist $(THEOS_STAGING_DIR)/Applications/Divisé.app/hdik
	rm -f $(THEOS_STAGING_DIR)/Applications/Divisé.app/embedded.mobileprovision
	rm -rf $(THEOS_STAGING_DIR)/Applications/Divisé.app/attach
	sudo fakeroot chmod 6755 $(THEOS_STAGING_DIR)/Applications/Divisé.app/Divisé
	sudo fakeroot chmod 6755 $(THEOS_STAGING_DIR)/Applications/Divisé.app/succdatroot
	sudo fakeroot chmod 0755 $(THEOS_STAGING_DIR)/Applications/Divisé.app/hdik
	sudo fakeroot chmod 0755 $(THEOS_STAGING_DIR)/Applications/Divisé.app/apfs_deletefs

after-install::
	install.exec 'uicache --path /Applications/Divisé.app/'

include $(THEOS_MAKE_PATH)/aggregate.mk
