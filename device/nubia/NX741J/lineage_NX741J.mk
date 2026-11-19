#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from NX741J device
$(call inherit-product, device/nubia/NX741J/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_NX741J
PRODUCT_DEVICE := NX741J
PRODUCT_MANUFACTURER := nubia
PRODUCT_BRAND := nubia
PRODUCT_MODEL := NX741J

PRODUCT_GMS_CLIENTID_BASE := android-nubia

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi_64-user 16 BQ2A.250705.001-BP2A.250605.031.A3 20261012.171910 release-keys" \
    BuildFingerprint=nubia/CN_PQ85A01/PQ85A01:16/BQ2A.250705.001-BP2A.250605.031.A3/20261012.171910:user/release-keys \
    DeviceName=PQ85A01 \
    DeviceProduct=CN_PQ85A01 \
    SystemDevice=PQ85A01 \
    SystemName=CN_PQ85A01
