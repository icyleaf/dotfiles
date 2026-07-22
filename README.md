# icyleaf's dotfiles

基于 [Chezmoi](https://chezmoi.io/) 声明式配置管理器进行构建与管理的个人 dotfiles 仓库。支持跨 macOS 和 Linux (GUI/Headless) 多环境的一键部署与生命周期初始化。

## 安装与快速开始

### 方式一：远程一键安装部署（推荐）

Chezmoi 支持在不克隆本仓库的情况下直接拉取并应用配置：

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply icyleaf
```

### 方式二：本地克隆初始化

如果您已经手动将本仓库克隆到了本地：

```bash
# 进入仓库目录并利用 bin/chezmoi 进行初始化和部署
cd ~/.dotfiles
./bin/chezmoi init --source "$PWD" --apply
```

> [!NOTE]
> 在首次运行 `init` 引导过程中，Chezmoi 会以交互式命令行提示询问您的 Git 姓名、邮箱以及当前是否为无 GUI 的 Headless 终端环境，并根据输入自动渲染生成适配当前平台的配置。

## 目录结构说明

- `dot_config/`：对应部署到 `~/.config/` 下的通用和 Linux 专属应用配置（例如 Hyprland, Waybar, Walker 等）。
- `dot_local/bin/`：部署到 `~/.local/bin/` 下的自定义可执行工具与维护脚本。
- `Library/`：对应部署到 macOS `~/Library/` 目录下的专用偏好文件（如 Alfred, iTerm2, LinearMouse 等）。
- `assets/`：存放非 dotfiles 的仓库静态资源，如 Plymouth 主题资产等。

## 集成测试验证

在修改或提交配置文件前，可以在本地运行集成测试脚本以确保模板渲染及依赖安装生命周期完全正常：

```bash
# 运行非侵入性沙盒测试
./.scratch/verify-chezmoi.sh
```

## 安全数据加密 (SOPS + Age)

配置中包含的敏感私密数据建议使用 SOPS + Age 进行统一解密与加密操作，具体的加密规则详见 [.sops.yaml](.sops.yaml) 配置文件。

```bash
# 解密 zsh 环境变量
sops -d --output-type dotenv dot_config/zsh/local.enc.zsh > dot_config/zsh/local.zsh

# 加密 zsh 环境变量
sops -d --input-type dotenv dot_config/zsh/local.zsh > dot_config/zsh/local.enc.zsh
```
