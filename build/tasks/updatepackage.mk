# Copyright (C) 2022 PixysOS Project
# Copyright (C) 2023 RisingOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -----------------------------------------------------------------
# RisingOS OTA update package

RISING_TARGET_UPDATEPACKAGE := $(PRODUCT_OUT)/$(BUNDLED_VERSION)-fastboot.zip
RISING_BUNDLED_UPDATEPACKAGE := $(PRODUCT_OUT)/$(LINEAGE_VERSION)-update.zip

# Scripts, Bootloader & Radio files
ifneq (,$(filter cheetah,$(CURRENT_DEVICE)))
UPDATE_LINUX_SCRIPT := vendor/rising/tools/update-linux-cheetah.sh
UPDATE_WINDOWS_SCRIPT := vendor/rising/tools/update-windows-cheetah.ps1
endif
ifneq (,$(filter oriole,$(CURRENT_DEVICE)))
UPDATE_LINUX_SCRIPT := vendor/rising/tools/update-linux-oriole.sh
UPDATE_WINDOWS_SCRIPT := vendor/rising/tools/update-windows-oriole.ps1
endif
ifneq (,$(filter panther,$(CURRENT_DEVICE)))
UPDATE_LINUX_SCRIPT := vendor/rising/tools/update-linux-panther.sh
UPDATE_WINDOWS_SCRIPT := vendor/rising/tools/update-windows-panther.ps1
endif
ifneq (,$(filter raven,$(CURRENT_DEVICE)))
UPDATE_LINUX_SCRIPT := vendor/rising/tools/update-linux-raven.sh
UPDATE_WINDOWS_SCRIPT := vendor/rising/tools/update-windows-raven.ps1
endif

ifneq (,$(filter oriole raven,$(CURRENT_DEVICE)))
	VENDOR_BOOTLOADER := vendor/google/$(CURRENT_DEVICE)/bootloader-$(CURRENT_DEVICE)-slider-1.3-10780582.img
	VENDOR_RADIO := vendor/google/$(CURRENT_DEVICE)/radio-$(CURRENT_DEVICE)-g5300q-230927-231102-b-11040898.img radio-$(CURRENT_DEVICE)-g5123b-125137-231014-b-10950115.img
endif
ifneq (,$(filter cheetah panther,$(CURRENT_DEVICE)))
	VENDOR_BOOTLOADER := vendor/google/$(CURRENT_DEVICE)/bootloader-$(CURRENT_DEVICE)-cloudripper-14.0-10825040.img
	VENDOR_RADIO := vendor/google/$(CURRENT_DEVICE)/radio-$(CURRENT_DEVICE)-g5300q-230927-231102-b-11040898.img
endif
.PHONY: updatepackage
updatepackage: $(INTERNAL_UPDATE_PACKAGE_TARGET)
	$(hide) ln -f $(INTERNAL_UPDATE_PACKAGE_TARGET) $(RISING_TARGET_UPDATEPACKAGE)
ifneq (,$(filter cheetah oriole panther raven,$(CURRENT_DEVICE)))
	$(hide) zip -j -u $(RISING_BUNDLED_UPDATEPACKAGE) $(RISING_TARGET_UPDATEPACKAGE) $(UPDATE_LINUX_SCRIPT) $(UPDATE_WINDOWS_SCRIPT) $(VENDOR_BOOTLOADER) $(VENDOR_RADIO)
endif
	@echo ""
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "  ______ _____ _______ _____ __   _  ______       _____  _______" >&2
	@echo " |_____/   |   |______   |   | \  | |  ____      |     | |______" >&2
	@echo " |    \_ __|__ ______| __|__ |  \_| |_____|      |_____| ______|" >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "                   rising from the bottom                       " >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "                                                                " >&2
	@echo "****************************************************************" >&2
	@echo " Size            : $(shell du -hs $(RISING_TARGET_UPDATEPACKAGE) | awk '{print $$1}')"
	@echo " Size(in bytes)  : $(shell wc -c $(RISING_TARGET_UPDATEPACKAGE) | awk '{print $$1}')"
	@echo " Package Complete: $(RISING_TARGET_UPDATEPACKAGE)               " >&2
	@echo " Package Complete: $(RISING_BUNDLED_UPDATEPACKAGE)               " >&2
	@echo "****************************************************************" >&2
	@echo ""

