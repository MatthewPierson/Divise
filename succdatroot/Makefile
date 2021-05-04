ARCHS = arm64
TARGET = iphone::10.3:8.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = succdatroot
succdatroot_FILES = main.c
succdatroot_CODESIGN_FLAGS = -S../Entitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
