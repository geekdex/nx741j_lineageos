# Phase 8: 首次完整编译进度记录（2026-11-19）

## 1. 当前状态
- **阶段**: Phase 8 进行中
- **已完成**:
  - `mka bootimage vendorbootimage recoveryimage` **已编译成功**（`out/target/product/NX741J/{boot,vendor_boot,recovery}.img`）。
  - `mka bacon` 正在 `ssh home:~/src/nx741j_lineageos/lineage-24.0` 运行，最近一次采样进度 `[40% 40999/102201]`（累计已完成超 12 万步）。
- **核心环境**:
  - 源码树: `ssh home:~/src/nx741j_lineageos/lineage-24.0`（Android 17 / `CP2A.260605.016`）
  - 预编译内核: `device/nubia/NX741J-kernel/`（原厂 `kernel` + `dtb.dtb` + `dtbo.img` + 410 个 `.ko`）
  - 内核 UAPI 头文件树: `kernel/nubia/NX741J-headers/`（硬链接自 `kernel_platform/common` + 8 个 QCOM 开源驱动 `include/uapi` + `dataipa` `drivers/platform/msm/include/uapi/linux/*.h` + `android_kernel_qcom_sm8850` 的 `msm_ion.h` / `msm_ion_ids.h`）

## 2. 已解决的编译阻断项（按顺序）
1. `vendor.qti.hardware.fingerprint@1.0` 重复定义：移除 `system_ext/lib64/` 副本，保留 `vendor/lib64/`。
2. 与 AOSP/QTI 源码编译冲突的预编译接口库：从 `proprietary-files.txt` 移除 `android.hardware.{biometrics.fingerprint-V4-ndk,gatekeeper-V1-ndk,gatekeeper@1.0,nfc-V2-ndk,secure_element-V1-ndk,vibrator-V2-ndk}`、`vendor.qti.hardware.{camera.aon-V1..3-ndk,camera.offlinecamera-V1..2-ndk,capabilityconfigstore-V1-ndk}`、`AvfQcvmManager-V1-ndk`、`libgatekeeper`、`libvibratorutils`、`libtensorflowlite_c`、`libz`。
3. `init.qti.display_boot.sh` 命名空间冲突：从 `device/nubia/NX741J/init/Android.bp` 和 `device.mk` 移除（由 `hardware/qcom-caf/sm8850/display` 提供）。
4. 补齐缺失专有依赖库：从真机拉取并加入 46+ 个相机/指纹/KeyMint/音频/QTI 库（含 `libchilog`、`libarcsoft_qnnhtp`、`libocl_runtime`、`libqnn_net_base`、`libmodemapi_vendor`、`libVoiceSdk`、`capabilityconfigstore-V1-ndk`、`libteec`、`libbcs`）。
5. 暂移除 `WfdService`（`system_ext` 无线投屏因缺少 Android 16 `libheif` 阻断 Soong）。
6. `extract-files.py` `blob_fixups` 补齐 Android 17 NDK 版本映射：
   - `keymint-service-spu-qti` / `libspukeymint.so`: `sharedsecret-V2-ndk` → `V1-ndk`
   - `com.qti.node.dewarp.so` / `offlinecamera-service-impl.so`: `allocator-V1-ndk` → `V2-ndk`
   - `offlinecamera-service-impl.so`: `offlinecamera-V2-ndk` → `V3-ndk`
   - `camx.device-impl.so`: `graphics.common-V5-ndk` → `V7-ndk`
7. 打包重复清理：移除 `vendor/firmware_mnt/`、`vendor_dlkm/lib/modules/*.ko`、`oat/`、`.fsv_meta`、`vibrator.service(.rc/.xml)`，以及 `device/` 与 `vendor/` 重叠的 8 个 init/config 文件；移除 `device.mk` 中不存在的 4 个包和 `product.prop` 中重复的 `ro.dalvik.vm.enable_uffd_gc=false`。
8. 头文件缺失修复：`ar_osal` 缺 `linux/msm_audio.h`、QCOM `gralloc` 缺 `linux/msm_ion.h` → 在 `ssh home` 构建 `kernel/nubia/NX741J-headers` 并于 `BoardConfig.mk` 配置 `TARGET_KERNEL_SOURCE` + `TARGET_FORCE_PREBUILT_KERNEL := true`。
9. `dataipa` UAPI 头文件缺失修复（`2026-11-19 22:12`）：
   - **报错**：`//hardware/qcom-caf/sm8850/dataipa/ipanat:libipanat` 编译 `src/ipa_ipv6ct.c` 与 `src/ipa_nat_map.cpp` 时报 `fatal error: 'linux/msm_ipa.h' file not found`（2 steps failed）。
   - **原因**：`hardware/qcom-caf/common/Android.bp` 将 `qti_ipa_kernel_headers` 指向 `generated_kernel_header_defaults`（由 `TARGET_KERNEL_SOURCE` 即 `kernel/nubia/NX741J-headers` 生成）；此前从原厂内核源码包 `vendor/qcom/opensource/` 拷贝 UAPI 头文件时，因 `dataipa` 的头文件位于 `drivers/platform/msm/include/uapi/linux/` 而非 `include/uapi/` 导致遗漏。
   - **修复**：从 `ssh home:~/src/nx741j_lineageos/vendor/qcom/opensource/dataipa/drivers/platform/msm/include/uapi/linux/` 复制 `msm_ipa.h`、`ipa_qmi_service_v01.h`、`rmnet_ipa_fd_ioctl.h` 至 `lineage-24.0/kernel/nubia/NX741J-headers/include/uapi/linux/`（同时核对 `vendor/qcom/opensource/` 下所有 9 个 `uapi` 目录均已覆盖）。
   - **验证**：执行 `m libipanat` 重新生成 `generated_kernel_includes` 并成功编译链接 `out/target/product/NX741J/vendor/lib64/libipanat.so`（耗时 `03:01`）。

## 3. 回家后如何继续
- 若当前电脑关机导致 `mka bacon` 的 SSH 会话中断，直接在家里主机进入 `tmux` 断点续跑即可（已编产物和 `ccache` 均已落盘，不会丢失进度）：
  ```bash
  tmux new -s build
  cd ~/src/nx741j_lineageos/lineage-24.0
  export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=~/.ccache
  source build/envsetup.sh
  breakfast NX741J
  mka bacon 2>&1 | tee build_bacon.log
  ```
- 若回到家后想在家里主机直接从头使用本次仓库同步的 `device/nubia/NX741J/`，记得先 `git pull` 把本地提交拉过去（注意：`lineage-24.0/device/nubia/NX741J/` 目前已通过 `rsync` 与本次工作区保持一致）。
