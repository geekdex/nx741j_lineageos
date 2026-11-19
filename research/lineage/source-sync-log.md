# Phase 4: LineageOS 23.2 Source Sync Log (`ssh home`)

## 1. 目标与环境
- **主机**: `ssh home` (`debian`, i5-12600K / 64GB RAM / 1.7TB 可用)
- **源码目录**: `~/src/nx741j_lineageos/lineage-23.2`
- **目标分支**: `lineage-23.2` (`android-16.0.0_r4`, Android 16)

## 2. 镜像与 Git 配置（实测）
由于单镜像高并发容易限流，采用 **LineageOS 走清华 TUNA + AOSP/git-repo 走中科大 USTC** 分流：

1. `~/.bashrc`:
   ```bash
   export REPO_URL="https://mirrors.ustc.edu.cn/aosp/git-repo.git"
   ```
   *(注：实测 `https://mirrors.ustc.edu.cn/lineageos/` 为 ROM 下载目录而非 Git 源码镜像，因此 LineageOS manifest 仍用 TUNA。)*

2. `~/.gitconfig`:
   ```ini
   [user]
       email = pan.hy@foxmail.com
       name = geekdex
   [url "https://mirrors.ustc.edu.cn/aosp/"]
       insteadOf = https://android.googlesource.com/
   ```

3. 初始化命令（已完成）：
   ```bash
   repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/lineageOS/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1
   ```
   - `.repo/manifests` 已就绪（`origin/lineage-23.2`, `84e40f4 manifest: Forks for 2026-11 ASB`）。

## 3. 同步过程问题与调优记录
1. **TUNA `Waiting in queue`**：
   - `repo init` 与 `repo sync` 初始拉取 manifest 时，TUNA `git-upload-pack` 出现并发排队（实测曾达 `Position: 132`），且 `repo sync` 默认带 `--quiet` 会隐藏排队提示，导致看似卡住。等待过队列后会自动恢复输出。
2. **USTC AOSP `HTTP 429` 限流**：
   - 使用 `-j6` 同步时，部分 AOSP 仓库（如 `device/common`、`device/generic/*`）返回 `error: 429` 并自动休眠 4 秒重试。
   - **处理建议**：若 `429` 重试过多或最后有 fetch error，可 `Ctrl+C` 后降并发为 `-j2` 或 `-j3` 继续断点续传（已拉取仓库保留在 `.repo/projects/`，不会丢失）：
     ```bash
     cd ~/src/nx741j_lineageos/lineage-23.2
     repo sync -c --no-tags --no-clone-bundle -j2
     ```
3. **`git-lfs` 依赖**：
   - 因初始化启用了 `--git-lfs`，同步前/若遇 LFS 报错需确保已安装：`sudo apt install -y git-lfs && git lfs install`。

## 4. 最终验证结果（2026-11-19）
- **状态**: `repo sync has finished successfully.`（`1164/1164` 全部完成）
- **最终调优**: 将 AOSP `insteadOf` 切回清华 TUNA 后以 `-j10` 跑满 40–45 MB/s 完成剩余约 207 个仓库。
- **体积与目录**: `262G`，顶层目录（`build/`, `frameworks/`, `device/`, `hardware/`, `system/`, `vendor/lineage/` 等）完整，`.repo` 项目数 `1164`。
- **工作区状态**: `repo status` 显示 `nothing to commit (working directory clean)`。
- **关键观察**: `device/qcom/sepolicy_vndr/` 在 `lineage-23.2` 中最高包含 `sm8750`，尚未包含 `sm8850`（`sm8850` 参考树目前在 `lineage-24.0`），Phase 5 需参考 `sm8750` + `lineage-24.0` 的 `sm8850` 适配策略。
