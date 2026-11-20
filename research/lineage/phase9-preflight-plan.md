# Phase 9 前置：安全与刷机预案（待用户备份并确认后执行）

> 本文档仅作预案记录，**未经用户明确确认，严禁执行任何解锁 Bootloader、刷写或擦除操作**。

## 1. 当前交付物状态（Phase 8 已完成）
- **源码与编译输出位置 (`ssh home`)**: `~/src/nx741j_lineageos/lineage-24.0/out/target/product/NX741J/`
  - `lineage-24.0-20261120-UNOFFICIAL-NX741J.zip` (`1.9G`)
  - `boot.img` (`96M`), `init_boot.img` (`8.0M`), `vendor_boot.img` (`96M`), `dtbo.img` (`72M`), `recovery.img` (`100M`), `vbmeta.img` (`64K`), `vbmeta_system.img` (`64K`), `super_empty.img` (`5.2K`)
- **关键工程目录 (`ssh home`)**:
  - `lineage-24.0/device/nubia/NX741J/`（与本 Git 仓库 `device/nubia/NX741J/` 同步一致）
  - `lineage-24.0/vendor/nubia/NX741J/`（1,900+ 项原厂 blobs，`extract-files.py` 已生成）
  - `lineage-24.0/device/nubia/NX741J-kernel/`（原厂 `kernel` + `dtb.dtb` + 截断校验后的 `dtbo.img` + 410 个 `.ko`）
  - `lineage-24.0/kernel/nubia/NX741J-headers/`（UAPI 头文件树）

## 2. Phase 9 四项安全计划（动手前逐项确认）

### 2.1 Backup（数据与原厂分区备份）
1. **个人数据备份（用户自行完成）**：解锁 Bootloader 会强制清空 `/data`，需提前备份微信/相册/认证器/重要文件。
2. **已有原厂镜像备份**：`stock_dump/images/`（仅在当前电脑，未入 Git）已保存 `_b` 活动槽位的 `boot_b.img`、`init_boot_b.img`、`vendor_boot_b.img`、`dtbo_b.img`、`recovery_b.img`、`vbmeta_b.img`、`vbmeta_system_b.img`（附 `SHA256SUMS`）。
3. **建议补充备份（解锁前利用临时 root 只读提取）**：
   - 备份 `persist`、基带 NV 相关分区（`modemst1`/`modemst2`/`fsg`/`fsc`），以及条件允许时备份原厂 `super` 分区镜像（约 18 GiB，用于极端情况下无官方包直接还原原厂系统）。
   - 若后续主要在家里 Debian 主机操作，建议将 `stock_dump/images/` 同步一份到家里主机留底。

### 2.2 Recovery（恢复环境验证）
- 优先测试 `recovery.img` + `vendor_boot.img`（或确认 `fastboot boot` 是否受支持）能否正常进入 Lineage Recovery 并识别 ADB Sideload / MTP / 触摸。

### 2.3 Rollback（原厂回退方案）
- 若刷入后无法启动或卡在启动阶段：
  - 通过 `fastboot` 切回原厂 `_b`（或将 `stock_dump/images/*_b.img` 原样刷回对应分区并还原 `vbmeta` 校验）+ 若已备份 `super` 则一并还原。
  - 若原厂 `_a` 槽位仍保留完整原厂系统，也可在 `fastboot` 查看 `current-slot` 并在确认安全时评估切换回退。

### 2.4 Flashing（解锁与刷入顺序 — 待确认）
1. 确认开启“开发者选项 -> OEM 解锁”及 USB 调试。
2. 确认 NX741J 的 Bootloader 解锁方式（标准 `fastboot flashing unlock` 或厂商特定流程）。
3. 首次刷机前先确认 `fastboot` 设备识别与当前活动槽位（`fastboot getvar current-slot`），再按顺序刷入 `vbmeta`（`--disable-verity --disable-verification` 视策略定）、`boot`/`init_boot`/`vendor_boot`/`dtbo`/`recovery`，最后通过 Lineage Recovery `adb sideload` 刷入 `lineage-24.0-20261120-UNOFFICIAL-NX741J.zip` 并格式化 `/data`。
