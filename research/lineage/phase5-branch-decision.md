# Phase 5 前置：分支可行性复核（2026-11-19）

## 1. 结论（待用户确认）
`lineage-23.2` **缺少 SM8850 / `canoe` 平台的全部 LineageOS 基础设施**；完整的 `canoe` 支持只存在于 `lineage-24.0`（Android 17, `android-17.0.0_r1`）。
建议 **将目标分支由 `lineage-23.2` 切换为 `lineage-24.0`**。

## 2. 证据（`ssh home` 实测）

| 项目 | `lineage-23.2`（已同步树） | `lineage-24.0`（`reference/` 浅克隆 + manifest） |
| :--- | :--- | :--- |
| `hardware/qcom-caf/common/qcom_boards.mk` | 最高 `sun`（UM 6.6），**无 `canoe`** | `QCOM_BOARD_PLATFORMS += canoe` |
| `qcom_defs.mk` | 无 `UM_6_12_FAMILY` | `UM_6_12_FAMILY := canoe` |
| `hardware/qcom-caf/sm8850/*`（audio agm/pal/mcs/primary-hal、display core/hal/intf、dataipa） | **不存在**（最高 `sm8750`） | manifest `snippets/lineage.xml` L161–170，分支 `lineage-24.0-caf-sm8850` |
| `device/qcom/sepolicy_vndr/sm8850` | **不存在**（远端无 `lineage-23.2-caf-sm8850` 分支） | `lineage-24.0-caf-sm8850` |
| Kernel 6.12 Kleaf 平台（`kernel/platform/kernel-6.12/build/kernel` 等） | 无 | `snippets/kernel-6.12.xml`（补齐 Phase 1 缺失的 `//build/kernel/kleaf`） |
| `android_kernel_qcom_sm8850{,-devicetrees,-modules}`（含 `canoe` 基础 DTS，补齐 Phase 1 缺失的 `soc-repo`） | 仅 `lineage-24.0` 分支 | ✅ |
| 官方参考设备 `oneplus/sm8850-common` + `oneplus/infiniti` | 仅 `lineage-24.0` 分支 | ✅ |

参考设备关键事实（`device/oneplus/sm8850-common@lineage-24.0`）：
- `TARGET_BOARD_PLATFORM := canoe`，`TARGET_KERNEL_VERSION := 6.12`，`TARGET_KERNEL_PLATFORM_TARGET := canoe_perf`，`BOARD_USES_GENERIC_KERNEL_IMAGE := true`
- `BOARD_SHIPPING_API_LEVEL := 202504`、`PRODUCT_SHIPPING_API_LEVEL := 36` —— **与 NX741J 完全一致**（`ro.board.api_level=202504` / `first_api_level=36`）
- Blobs 来自 Android 16 原厂系统（OxygenOS 16），证明 **Android 17 system + Android 16 (202504) vendor blobs** 是 LineageOS 官方已验证的组合
- 分区与启动链：boot/init_boot/vendor_boot v4、`dtbo`、`recovery`、`vendor_dlkm`/`system_dlkm`、`qti_dynamic_partitions`、AVB `vbmeta_system` + `vbmeta_vendor` —— 与 NX741J 分区结构一致（NX741J 无 `vbmeta_vendor` 需核实）

## 3. 方案对比

| 方案 | 工作量 | 风险 |
| :--- | :--- | :--- |
| **A. 切换 `lineage-24.0`（推荐）** | 重新同步 ~260–300 GB；之后可直接以 OnePlus sm8850-common 为结构模板 | Android 17 与原厂 Android 16 vendor 跨一个大版本（官方参考设备已验证可行） |
| B. 留在 `lineage-23.2` 并自行回移植 `canoe` | 需回移植 qcom-caf common、sm8850 HAL 全套、sepolicy_vndr sm8850、kernel 6.12 平台 manifest；这些仓库基于 24.0 的 AOSP API，存在大量构建冲突 | 工作量极大、无上游维护、后续无法跟进安全更新 |

## 4. 用户决定（2026-11-19）
- 采用方案 A，**原地切换**（用户已自行备份 23.2 代码），由用户手动执行每一步；Agent 只提供命令。
- 注意：`kernel-6.12.xml` 片段**未被 `default.xml` include**（L1105 仅 include `snippets/lineage.xml`），官方是通过 `breakfast` 的 roomservice 读取 `lineage.dependencies`（`"type": "kernel", "version": "6.12"`）拉取。本项目将在 Phase 7 用 `.repo/local_manifests/` 手动声明。

## 5. 原始执行草案（新目录方式，已被第 4 节替代）
- 新目录：`ssh home:~/src/nx741j_lineageos/lineage-24.0`（保留现有 `lineage-23.2` 不动；磁盘剩余 1.3 TB，充足）
- 命令：
  ```bash
  mkdir -p ~/src/nx741j_lineageos/lineage-24.0 && cd ~/src/nx741j_lineageos/lineage-24.0
  repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/LineageOS/android.git -b lineage-24.0 --git-lfs --depth=1
  repo sync -c --no-tags --no-clone-bundle -j8
  ```
- Kernel 6.12 平台仓库属于 `kernel-platform-612` 组，可能需 `repo init -g default,kernel-platform-612` 或通过 `roomservice`/local_manifest 按需拉取（同步前确认）。
