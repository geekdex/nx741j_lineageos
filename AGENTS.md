# AGENTS.md — Nubia Z80 Ultra (NX741J / PQ85A01) LineageOS Bring-up

## 1. 唯一最终目标

为 **Nubia Z80 Ultra（NX741J / PQ85A01）** 适配 **LineageOS**，并在真实设备上成功启动、稳定运行，完整恢复主要硬件与系统功能：

- 基础系统：LineageOS 构建、可刷写镜像、真机启动、ADB、Recovery / Fastbootd
- 核心硬件：显示、触摸、GPU、音频、Wi-Fi、Bluetooth、Camera、指纹（超声波屏下）、传感器、GPS、NFC
- 通信与电源：移动网络、电话 / SMS、5G / IMS / VoLTE、USB / OTG / 充电
- 安全与稳定：FBE 加密、SELinux Enforcing、合理 AVB / Verified Boot 架构、CTS / VTS 与日常稳定性

> 不把“编译通过”或“能开机”误认为项目完成。任何结论必须以真实设备、ADB/Fastboot、内核源码、官方固件、AOSP 或 LineageOS 源码为依据；未验证结论必须标注为 **未验证**。

---

## 2. 已确认设备事实（Phase 0 + Phase 1）

> 若未来从真机、官方固件或源码中发现冲突，以最新真实证据为准并更新本文档。

| 项目 | 已确认值 |
| :--- | :--- |
| **Model** | `NX741J` (`nubia Z80 Ultra`) |
| **Codename** | `PQ85A01` (`CN_PQ85A01`) |
| **ZTE 内核板级代号** | `qwbarley` / `aston` |
| **硬件版本** | `NX741JHW1.0` |
| **SoC / 平台** | Qualcomm `SM8850` / `canoe` (`arm64-v8a`, `aarch64`, 4K pages) |
| **原厂系统** | `NebulaAIOS2.0.29MR2_NX741J` (`user/release-keys`) |
| **Android / SDK / Vendor API** | Android `16` / SDK `36` / `ro.vendor.api_level=202504` |
| **Kernel / GKI** | `6.12.23-android16-5-...-4k` (`android16-6.12`, KMI gen 5, Clang 19.0.1 r536225) |
| **分区架构** | A/B (`_b` 当前活动)、Virtual A/B（压缩 + userspace snapshots）、Dynamic Partitions (`super`) |
| **启动链分区** | `boot_a/b`, `init_boot_a/b`, `vendor_boot_a/b`, `dtbo_a/b`, `recovery_a/b` |
| **Logical 分区** | `system`, `system_ext`, `product`, `vendor`, `vendor_dlkm`, `system_dlkm`, `odm` (均为 `erofs`) |
| **安全与加密** | Bootloader `locked`、AVB `1.3` (`green`)、SELinux `Enforcing`、FBE (`file` + `inlinecrypt` + `wrappedkey_v0`) |
| **内核源码包状态** | `NX741J_W(16)_Kernel(6.12.23).tar.gz` 已在 `ssh home` 解压；含 GKI 6.12.23、QCOM 开源驱动与 `qwbarley` DTBO overlay，**缺失** `//build/kernel/kleaf` 与 `//soc-repo`（`canoe.dtsi` 等） |

---

## 3. 开发环境与任务分工

### 3.1 当前电脑（AI 工作空间：`~/src/nx741j_lineageos`）
- 职责：与用户交互、阅读/分析文档与轻量代码、维护 `AGENTS.md` / `ROADMAP.md` / `research/`、Git 小型修改、连接当前 USB 手机执行只读 `adb`。
- **禁止**：在此机器同步完整 AOSP / LineageOS 源码或执行 Ninja / Soong / kernel 大规模编译。

### 3.2 家里 Debian 主机（`ssh home`：`~/src/nx741j_lineageos`，i5-12600K / 64GB RAM / ~1.7TB 可用）
- 职责：LineageOS `repo init` / `repo sync`、大型 Git 仓库、Android / Kernel 编译（Ninja / Soong / Kleaf / ccache）、官方 ROM 解包与镜像提取（`payload.bin` / `super` / `erofs`）、大规模源码搜索（`rg`/`grep`）、CTS/VTS。
- 跨机传输大文件前必须先明确：`SOURCE`、`TARGET`、`文件大小`、`传输原因`。

### 3.3 手机 ADB 归属
- 每次使用 `adb` 前先检查 `adb devices` 确认手机连接在哪台主机（当前 USB 直连本地工作电脑）。

### 3.4 国内网络与镜像规则
- `ssh home` 位于中国大陆网络环境；大型源码同步优先使用可靠国内镜像（清华 TUNA、中科大 USTC、阿里云或官方可访问镜像），严禁猜测镜像 URL。
- **已验证分流配置**（记录见 `research/lineage/source-sync-log.md`）：
  - `LineageOS/*` 走清华 TUNA（`https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/`）
  - `AOSP` 与 `REPO_URL` 走中科大 USTC（`https://mirrors.ustc.edu.cn/aosp/` 与 `https://mirrors.ustc.edu.cn/aosp/git-repo.git`）
  - **并发建议**：`repo sync` 并发建议 `-j2` 至 `-j4`（实测 `-j6` 会触发 USTC `429` 限流，TUNA 高峰期也会排队）。
- 执行 `repo sync` 前必须先汇报目标分支、预计磁盘占用、镜像地址与具体命令，获用户确认后再执行。
- **Git 同步边界**：本工作空间通过 `.gitignore` 排除压缩包、镜像与源码树（`*.tar.gz`、`stock_dump/`、`lineage-23.2/` 等），仅保留 `AGENTS.md`、`research/` 等文档与配置用于跨机 Git 同步。

---

## 4. 核心工程与安全原则

1. **只读优先与刷机安全**：未经用户明确确认，严禁 `fastboot flash` / `erase` / `format`、`wipe`、解锁 Bootloader 或修改 `boot` / `vendor_boot` / `dtbo` / `vbmeta` / `super`。进入刷机阶段前必须先制定 `Backup` / `Recovery` / `Rollback` / `Flashing` 四项计划。
2. **复用原厂实现**：以原厂 NebulaAIOS（Framework / HAL / Vendor / init / SELinux / kernel / DT / firmware）为硬件行为基准，不凭经验猜测。
3. **Vendor Blobs**：`vendor/nubia/NX741J/` 仅允许来自 NX741J 原厂系统、官方 ROM / OTA 或合法官方固件；禁止混用其他机型或不同 SoC 的二进制文件。
4. **Device Tree**：逐步构建 `device/nubia/NX741J/`，每项关键配置必须有明确出处（原厂配置 / kernel source / stock image / QCOM 源码 / LineageOS 参考设备 / AOSP 文档）。
5. **参考设备优先级**：`SM8850` > `canoe` > Android 16 > Kernel 6.12 > 同 QCOM HAL > 同分区布局 > 同 vendor 架构 > Nubia/ZTE > 其他 QCOM 旗舰。仅学习结构与通用配置，硬件差异以 NX741J 实测为准。
6. **逐层排查**：按 `App -> Framework -> System Service -> Binder/AIDL/HIDL -> HAL -> Vendor -> Kernel -> DT -> Firmware -> Hardware` 定位问题。
7. **SELinux**：最终必须 `Enforcing`；禁止以 `permissive` 作为最终方案，禁止无脑 `audit2allow`，须分析具体 `domain/type/class/permission` 后编写最小权限规则。

---

## 5. 项目阶段路线（Phase 0 – Phase 14）

- [x] **Phase 0**：设备调查
- [x] **Phase 1**：Kernel source 分析（产物见 `research/kernel/`）
- [x] **Phase 2**：Stock firmware / OTA 获取与分析（产物见 `research/stock/` 与 `stock_dump/`）
- [x] **Phase 3**：LineageOS branch / reference device 调研（产物见 `research/lineage/`）
- [x] **Phase 4**：建立 LineageOS source（`ssh home:~/src/nx741j_lineageos/lineage-24.0`，Android 17 / `lineage-24.0`，1240 repos 校验完整，含 `canoe` / `sm8850` 平台支持）
- [x] **Phase 5**：建立 device tree（[device/nubia/NX741J/](file:///home/panhy/src/nx741j_lineageos/device/nubia/NX741J/) 初版已建立，待 Phase 6–8 联动验证）
- [x] **Phase 6**：建立 vendor tree / proprietary blobs（`ssh home:~/src/nx741j_lineageos/lineage-24.0/vendor/nubia/NX741J/` 已由 `extract-files.py` 生成）
- [x] **Phase 7**：Kernel / DT / vendor 集成（采用原厂 GKI `Image` + `dtb` + `dtbo` + 410 个 `.ko` 预编译模块，`breakfast NX741J` 解析通过）
- [x] **Phase 8**：第一次完整编译（`lineage-24.0-20261120-UNOFFICIAL-NX741J.zip` 与全套分区镜像已编译生成）
- [ ] **Phase 9**：第一次启动 *(下一步)*
- [ ] **Phase 10**：基础 Bring-up
- [ ] **Phase 11**：硬件逐项 Bring-up
- [ ] **Phase 12**：SELinux / Security / Encryption
- [ ] **Phase 13**：CTS / VTS / 稳定性
- [ ] **Phase 14**：最终刷机 / 日常使用

---

## 6. 协作与汇报规范

采用**人机协同、逐步确认**模式：Agent 负责调研、分析、规划、编写与只读验证；关键外部输入（如官方 ROM 获取、Bootloader 解锁/刷机、未知硬件行为）由用户补充或确认执行。

每完成一个阶段，输出必须包含以下 7 个部分：
1. **已确认**（真实证据支撑）
2. **推测**（尚未验证）
3. **缺失**（当前缺少的输入/条件）
4. **已完成**（实际完成的工作）
5. **修改**（改动的文件列表）
6. **下一步**（最合理的后续动作）
7. **风险**（编译失败、bootloop、功能缺失、数据丢失、变砖等风险）
