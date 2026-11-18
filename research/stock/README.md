# NX741J Stock Firmware & Dump Analysis (Phase 2)

## 1. 数据来源
通过临时 root (`adb root`, KernelSU `u:r:ksu:s0`) 对当前运行 `NebulaAIOS2.0.29MR2_NX741J`（活动槽位 `_b`）执行**纯只读**提取，保存于本地 `stock_dump/` 与 `research/stock/`。

## 2. 启动链原厂镜像 (`stock_dump/images/`)

| 镜像文件 | 块设备 | 大小 | Header / 格式 |
| :--- | :--- | :--- | :--- |
| `boot_b.img` | `/dev/block/sde55` | 96 MB (`100663296` B) | `ANDROID!` v4 (`kernel_size=39819776`, `ramdisk=0`) |
| `init_boot_b.img` | `/dev/block/sde71` | 8 MB (`8388608` B) | `ANDROID!` v4 (`kernel=0`, `ramdisk_size=2916955`) |
| `vendor_boot_b.img` | `/dev/block/sde67` | 96 MB (`100663296` B) | `VNDRBOOT` v4 (`page_sz=4096`, `ramdisk_size=8782846`) |
| `dtbo_b.img` | `/dev/block/sde59` | 72 MB (`75497472` B) | DTBO image |
| `recovery_b.img` | `/dev/block/sde69` | 100 MB (`104857600` B) | `ANDROID!` v4 (`kernel=0`, `ramdisk_size=20482245`) |
| `vbmeta_b.img` | `/dev/block/sde58` | 64 KB (`65536` B) | AVB 1.3 vbmeta |
| `vbmeta_system_b.img` | `/dev/block/sda9` | 64 KB (`65536` B) | AVB 1.3 vbmeta_system |

校验文件：`stock_dump/images/SHA256SUMS`。

## 3. 固件与系统配置 (`stock_dump/partitions/` & `research/stock/`)

- **已提取固件与模块**:
  - `vendor_firmware/` (42 MB, 109 files; 含 `wlan/qca_cld/peach_v2/` — 确认 Wi-Fi 为 Qualcomm Peach v2)
  - `vendor_firmware_mnt/` (185 MB, 584 files — Modem/DSP/ADSP/CDSP 等核心固件)
  - `vendor_dsp/` (59 MB, 120 files)
  - `vendor_bt_firmware/` (2.0 MB, 68 files)
  - `vendor_soccp_firmware/` (2.7 MB, 2 files)
  - `vendor_dlkm/` (69 MB, 309 files — 全部 `.ko` 内核模块)
  - `vendor_etc_init/` (154 files) & `odm_etc/` (20 files)
- **已提取核心配置 (`research/stock/`)**:
  - `config.gz`: 当前运行内核完整 `.config` (47 KB)
  - `cmdline.txt`: 含 `kvm-arm.mode=protected`、`bootconfig`、`msm_drm.dsi_display0=qcom,mdss_dsi_bf375_rm692h5_6p8_dev0_dsc_cmd:`
  - `bootconfig.txt`: Android bootconfig 参数
  - `fstab.qcom`: 完整挂载与加密配置（`erofs` + `f2fs` + `inlinecrypt` + `wrappedkey_v0` + AVB）
  - `vintf/` (122 files) & `selinux/` (14 files)
  - `vendor_build.prop`、`odm_build.prop`、`system_build.prop`、`system_ext_build.prop`、`product_build.prop`
  - `partition_files.txt`: `/vendor`、`/odm`、`/vendor_dlkm`、`/system_ext`、`/product` 目录索引（7,389 行）
- **CPU / 渲染关键属性 (`vendor_build.prop`)**:
  - `dalvik.vm.isa.arm64.variant=oryon`
  - `ro.hwui.use_vulkan=true`
  - `ro.board.api_frozen=true`
