# LineageOS Branch, Mirror & Reference Device Research (Phase 3)

## 1. LineageOS 分支调研

在 `ssh home` 实测 `git ls-remote` 与 `default.xml` 确认：

| 分支 | AOSP Base Tag | 状态 | 适用性 |
| :--- | :--- | :--- | :--- |
| `lineage-23.0` | `android-16.0.0_r1` | TUNA 已同步 | Android 16 初始版本 |
| `lineage-23.2` | `android-16.0.0_r4` | TUNA 已同步 | **推荐目标分支**（对应 Android 16 QPR/更新版本，匹配本机 SDK 36 / 2026-08 安全补丁） |
| `lineage-24.0` | `android-17.0.0_r1` | TUNA 已同步 | Android 17（暂不直接用于首版适配，但参考设备在此分支） |

## 2. 国内镜像确认（`ssh home` 实测可用）

- **清华大学 TUNA 镜像**:
  - LineageOS: `https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/`
  - Manifest: `https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/LineageOS/android.git`（实测与 GitHub commit hash 完全一致）
  - AOSP: `https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/`（实测包含 `android-16.0.0_r1` 与 `android-16.0.0_r4`）
  - `git-repo`: `https://mirrors.tuna.tsinghua.edu.cn/git/git-repo`
- **预计磁盘与时间**（供 Phase 4 确认后执行）：
  - LineageOS 23.2 源码 + 编译环境预计占用 **300 GB – 450 GB**（`ssh home` 当前可用 **1.7 TB**，空间充足）。
  - 建议使用 `--depth=1`（或标准浅克隆视后续需求）+ TUNA 镜像加速。

## 3. 参考设备调研

- **NX741J / PQ85A01 / qwbarley 公开设备树**: 暂未发现现成的 LineageOS 官方或社区完整 `NX741J` device tree（需从零构建）。
- **同平台 Qualcomm SM8850 (`canoe`) 官方 LineageOS 参考仓库**:
  - `LineageOS/android_device_oneplus_sm8850-common`（当前分支 `lineage-24.0`）
  - `LineageOS/android_kernel_qcom_sm8850-devicetrees`（当前分支 `lineage-24.0`）
  - `LineageOS/android_kernel_oneplus_sm8850`（含 `canoe` 目标配置）
  - `LineageOS/android_kernel_oneplus_sm8850-devicetrees`
- **参考使用原则**: 仅用于学习 SM8850 / `canoe` 平台 `BoardConfig.mk`、`vendor_boot`/`init_boot`/`vendor_dlkm` 架构、Android 16/17 QCOM HAL 组织方式；所有硬件差异以 NX741J 真机 dump 与 `2.0.29MR2` 原厂实现为准。
