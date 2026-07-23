# ADR-0002: Declarative Externals via `.chezmoiexternal.toml.tmpl`, Bootstrap Script, and Unified Linux Package Installation

**Status**: Accepted  
**Date**: 2026-07-24

## Context

Managing system configuration dependencies and third-party tools (Zsh plugin manager `zinit`, Tmux plugin manager `tpm`, Neovim configs like `lazyvim`, and system packages like `fzf`, `btop`, etc.) requires a balance between simplicity, reliability, and cross-platform flexibility.

Previously, these dependencies were managed via custom shell scripts (`run_once_install-zinit.sh`, `run_once_install-tpm.sh`, `run_once_install-lazyvim.sh`). Additionally, system package installation was automated on macOS via Homebrew bundles, but left entirely manual on Linux.

Three main problems were identified:
1. **Imperative Custom Scripts**: Shell scripts managing `git clone` or `curl` for plugins are prone to failure, lack caching/update management by Chezmoi, and require custom boilerplate logic to ensure idempotency.
2. **Chezmoi Cold-Start**: A raw, freshly-installed system has no `git`, `chezmoi`, or `age` (used to decrypt secrets) installed. Chezmoi cannot bootstrap these prerequisites on its own.
3. **Linux Package Drift**: There was no automated mechanism to install required Linux packages, despite having a custom package manager abstraction script `pm.sh`.

## Decision

1. **Use Declarative Externals**: Delete custom plugin installer scripts (`run_once_install-zinit.sh`, `run_once_install-tpm.sh`, `run_once_install-lazyvim.sh`) and configure `.chezmoiexternal.toml.tmpl` to manage third-party repositories declaratively.
2. **Provide a Bootstrap Script**: Add `install.sh` at the repository root to detect the host platform, install basic dependencies (`git`, `chezmoi`, `age`), and trigger `chezmoi init --apply`.
3. **Automate Linux Packages**: Add `linux-packages.txt` at the repository root (excluded from deployment via `.chezmoiignore`), and write a `run_onchange_install-packages-linux.sh.tmpl` script that uses `pm.sh` to install all packages listed in `linux-packages.txt` on Linux hosts.

## Reasons

- **Declarative and Idempotent**: `.chezmoiexternal` allows Chezmoi to manage external repository states directly. Chezmoi optimizes download caching, tracks updates, and ensures directories exist without custom shell logic.
- **Pure-Go Compatibility**: `.chezmoiexternal` runs natively in Chezmoi, reducing dependency on external tools or shells during dotfiles initialization.
- **Easy Bootstrapping**: A raw machine only needs `curl -fsSL https://raw.githubusercontent.com/.../install.sh | sh` to get a fully working environment, including secret decryption keys.
- **Unified Package Management**: Using `pm.sh` inside `run_onchange_install-packages-linux.sh.tmpl` leverages the existing robust package wrapper to install pacman/apt/yay/brew packages uniformly, depending on which package manager is present on the Linux host.
- **Separation of Concerns**: Storing Linux packages in `linux-packages.txt` under the repository root keeps the package list isolated from executable installer logic and avoids cluttering the home directory.

## Trade-offs Accepted

- **Network Overhead**: Chezmoi checking externals can sometimes add network queries during `chezmoi apply`, though it caches aggressively.
- **Pre-requisite Detection**: The `install.sh` bootstrap script must use platform-specific commands (like `apt`, `brew`, `pacman`) imperatively, but this is limited only to the initial bootstrapping phase of the three base utilities.
