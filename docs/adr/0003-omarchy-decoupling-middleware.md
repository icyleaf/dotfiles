# ADR 0003: Omarchy Decoupling and Middleware Wrappers

## Status
Accepted

## Context
Our desktop configuration (Hyprland, Waybar) relies on commands and assets from `omarchy` (a set of scripts and defaults originally cloned to `~/.local/share/omarchy`). Over-reliance on a global, mutable `omarchy` setup leads to:
1. **Upstream drift**: Changes upstream to hotkeys, commands, or defaults can cause configuration issues or breaking changes.
2. **Portability limitations**: If a machine does not have Omarchy installed, desktop configurations and keybindings break entirely, violating the "clean, standalone dotfiles" principle.
3. **Customization friction**: Overwriting complex default hotkeys (like media keys or workspace managers) requires copying or unbinding entire files, which gets out of sync when upstream files update.

## Decision
We decouple our dotfiles configuration from Omarchy using a **Vendored Submodule** and a **Middleware Command Abstraction Layer**.

### 1. Vendored Git Submodule
We track Omarchy as a git submodule in the repository root at `vendor/omarchy`:
* We lock the Omarchy version to a known-stable commit.
* Upgrade of Omarchy is explicitly done via `git submodule update --remote vendor/omarchy`, allowing reviewable changes.
* We ignore `vendor/` in Chezmoi deployment via `.chezmoiignore`.

### 2. Automatic Symlink Deployment
A new run-once script `run_once_setup-omarchy-vendor.sh.tmpl` creates a symlink from `~/.local/share/omarchy` to the vendored directory under the Chezmoi source path (`{{ .chezmoi.sourceDir }}/vendor/omarchy`). This guarantees that:
* Any legacy config files expecting `~/.local/share/omarchy/...` still resolve properly.
* The symlink is set up during bootstrapping before configurations are initialized.

### 3. Middleware Wrappers (`icy-*`)
To support slotting out Omarchy in the future (Scenario Y), we introduce an abstraction layer under `dot_local/bin/` (deployed to `~/.local/bin/`) using the user's custom `icy-` prefix.
* We define wrappers for the 20 most-frequently-used Omarchy commands (e.g. `icy-system-lock`, `icy-menu`, `icy-launch-browser`).
* These wrappers initially delegate to the corresponding `omarchy-*` binary if available.
* All keybindings (`bindings.conf`), autostart scripts (`autostart.conf`), lock daemons (`hypridle.conf`), and status bar modules (`modules.jsonc`) are modified to invoke the `icy-*` commands instead of direct `omarchy-*` commands.

```
+-----------------------------------+
|  Hyprland / Waybar Configuration  |
+-----------------+-----------------+
                  |
                  v (Calls icy-system-lock)
+-----------------+-----------------+
|   icy-* Middleware Wrapper Layer  |  <--- Can be swapped to custom logic
+-----------------+-----------------+
                  |
                  v (Delegates to omarchy-system-lock)
+-----------------+-----------------+
|       Omarchy (Submodule Link)    |
+-----------------------------------+
```

## Consequences
* **Decoupling**: The dotfiles' internal configs no longer have direct mentions of `omarchy-*` binaries, making the setup ready for custom replacements.
* **Hermetic Setup**: Bootstrapping dotfiles will automatically pull down the fixed Omarchy revision as part of the submodule update, without relying on external system-wide scripts to clone it.
* **Controlled Upgrades**: All upstream changes to Omarchy's code are now visible via git submodule diffs, preventing sudden breaking changes when upgrading packages.
