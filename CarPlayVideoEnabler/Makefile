ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CarPlayVideoEnabler

CarPlayVideoEnabler_FILES = Tweak.xm
CarPlayVideoEnabler_CFLAGS = -fobjc-arc -Wno-declaration-after-statement
CarPlayVideoEnabler_FRAMEWORKS = UIKit Foundation CoreLocation

include $(THEOS_MAKE_PATH)/tweak.mk

after-package::
	@echo ""
	@echo "========== 构建完成 =========="
	@echo ".deb:  $(THEOS_PACKAGE_DIR)/com.monkeycode.carplayvideoenabler_*_$(THEOS_PACKAGE_ARCH).deb"
	@echo ".dylib 路径: .theos/obj/debug/$(TWEAK_NAME).dylib (可用于 TrollFools 注入)"
	@echo "=============================="
	@echo ""
