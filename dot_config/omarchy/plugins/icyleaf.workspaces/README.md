# Multi-Monitor Workspaces (`icyleaf.workspaces`)

A status bar widget plugin for [Omarchy](https://github.com/omarchy/omarchy) designed for multi-display Hyprland desktop setups.

It provides independent per-display workspace sets, physical monitor identity badges with real-time compositor focus tracking, smooth mouse interactions, and a decoupled IPC protocol for keybindings.

---

## Key Features

- **Monitor-Anchored Locality**: Each status bar widget instance binds strictly to its hosting physical monitor (`barWindow.screen`), ensuring that each screen independently displays its own assigned workspace range without global focus interference.
- **Monitor Identity Badge (`󰍹 M1`, `󰍹 M2`, ...)**:
  - Displays the monitor index and connector name (`󰍹 M1`, `󰍹 M2`, etc.).
  - Shows active focus highlights when the compositor's global keyboard/mouse focus rests on that display.
  - Hovering reveals detailed connector & panel information via tooltip (e.g. `DP-1 (RTK UHD demoset-1)`).
  - Clicking the badge immediately transfers compositor focus to that monitor.
- **Independent 10-Slot Allocation**:
  - Monitor 0 (`M1`): Workspaces `1` – `10` (slots `1..9, 0`)
  - Monitor 1 (`M2`): Workspaces `11` – `20` (slots `1..9, 0`)
  - Monitor 2 (`M3`): Workspaces `21` – `30` (slots `1..9, 0`)
- **Direct Hyprland Lua IPC Dispatch**: Dispatches focus and window relocation commands atomically via Hyprland's internal Lua socket, eliminating external bash subshell execution overhead.
- **Per-Monitor Layout Preview Overlay**: Right-click any Monitor Identity Badge to summon a full-screen, read-only overlay of the whole display topology on that badge's screen. Every enabled physical monitor is drawn as a compact-pack card preserving the real top→bottom / left→right arrangement and aspect ratio, showing its active workspace's windows as rectangles (tiled, floating, fullscreen, and Hyprland groups collapsed to a single frame) plus a fixed 10-slot occupancy strip. Live-updates from Hyprland events while open. Click a card to focus that monitor and dismiss; `Esc`/empty-space click dismisses; arrow keys navigate between cards and `Return` focuses the selected monitor.
- **Decoupled Shell IPC Interface**: Exposes standard `focus`, `move`, `movesilent`, and `preview` methods via `IpcHandler`, allowing Hyprland keybindings to remain clean and decoupled from workspace calculation logic.
- **Per-Workspace App Icons**: Occupied slots show the icon of the largest window's app instead of the slot number. GUI apps resolve through their `.desktop` entry and your icon theme with no configuration; terminal windows are probed with `pstree` so the TUI app actually running inside (yazi, btop, lazygit, claude, ...) gets its own icon. Empty slots keep their number, the active occupied slot adds an accent underline, and the workspace number is always available in the slot tooltip. See [App Icons](#app-icons).
- **Rich Mouse Interactions**:
  - **Left-Click**: Switch to target workspace.
  - **Right-Click**: Move active window to target workspace silently without following.
  - **Mouse Wheel**: Cycle through workspaces on the current monitor.
  - **Click Monitor Identity Badge (Left)**: Focus target display.
  - **Click Monitor Identity Badge (Right)**: Toggle the Per-Monitor Layout Preview Overlay on that display.
- **Multi-Special Workspace Scratchpads & Quick Picker Overlay**:
  - Configurable scratchpad drawers (`silent`, `term`, `chat`, `music`).
  - **Quick Picker Overlay (`SUPER + ALT + S`)**: Displays a centered modal listing all scratchpads with number keys `1`–`4` for single-stroke switching, `Shift + 1–4` for moving windows in, and `Esc` to close.
  - **Permanent Bar Icons**: Mini badges (`󰏤`, ``, `󰭹`, `󰎆`) rendered on the primary display bar for one-click mouse access.
  - **Display Modes (`specialDisplayMode`)**: `"primaryOnly"` (default), `"allWhenOccupied"`, `"allAlways"`.

---

## App Icons

When `showAppIcons` is enabled (the default), every occupied workspace slot renders the icon of the largest window on that workspace; empty slots keep their number. The active occupied slot adds a small accent underline so you can still tell where you are.

Icons resolve in four tiers, and the first three need no configuration:

| What you're running | Where its icon comes from | You do |
| :--- | :--- | :--- |
| Any GUI app | its `.desktop` entry + your icon theme | nothing |
| Common TUI apps (`btop`, `nvim`, `vim`, `htop`, `lazygit`, ...) | your icon theme | nothing |
| Apps in the plugin's `icons/` directory | this repo/plugin | drop a PNG/SVG |
| Anything else | `iconOverrides` | one setting entry |

Where a window class resolves to nothing, a generic executable icon is shown as a last resort.

### Why terminal apps are special

A terminal's window class is always the terminal (`kitty`, `alacritty`), never what runs inside it. Each window's process tree is scanned with `pstree` (~3 s cadence, one serialized process, cached per pid) so `yazi`, `btop`, `lazygit`, `claude` and friends show their own icon. When a TUI app quits but the terminal stays open, the slot reverts to the terminal's icon within a few seconds. Shells and multiplexers are deliberately skipped: the probe takes the first match, so listing `tmux` or `bash` would shadow whatever runs inside them.

### Adding an icon for an app that has none

The filename **is** the configuration. Drop a transparent PNG or SVG named after the process into the plugin's `icons/` directory (`icons/<process>.png`); it is picked up within ~30 s, no restart needed.

If a process name cannot line up with an icon name, add an `iconOverrides` entry to the widget's settings:

```json
"iconOverrides": [
  { "process": "nvim", "icon": "icons/neovim.png" }
]
```

### Finding a process name

It is not always the command you type — wrappers can show up as `node` or `python3`. List what is actually running under each window with:

```bash
hyprctl clients -j | jq -r '.[] | "\(.pid)\t\(.class)"'
```

### Settings

| Setting | Default | What it does |
| :--- | :--- | :--- |
| `showAppIcons` | `true` | Off gives plain numbers everywhere |
| `monochromeIcons` | `true` | Tint icons to the bar foreground; ignored on light themes and transparent bars, where icons keep their own colours |
| `iconScale` | `1.0` | Icon size multiplier |
| `iconOverrides` | `[]` | Explicit `{ process, icon }` mappings |

### Requirements

`pstree` (from `psmisc`). Icons for GUI apps and common TUI apps come from your icon theme, so no bundled assets are required. The command under [Finding a process name](#finding-a-process-name) additionally uses `jq`.

---

## Installation & Deployment

This plugin is managed via [Chezmoi](https://chezmoi.io) within `dot_config/omarchy/plugins/icyleaf.workspaces`.

1. Synchronize dotfiles and apply configuration:
   ```bash
   chezmoi apply
   ```

2. Restart the Omarchy status bar:
   ```bash
   omarchy-restart-shell
   ```

---

## Hyprland Keybindings Setup

Add the following snippet to your `~/.config/hypr/bindings.lua` (or `dot_config/exact_hypr/bindings.lua`):

```lua
-- Special workspace scratchpads (delegated to icyleaf.workspaces plugin via IPC)
o.bind("SUPER + S", "Toggle silent scratchpad", "omarchy-shell -q icyleaf.workspaces toggleSpecial silent")
o.bind("SUPER + SHIFT + S", "Move window to silent scratchpad", "omarchy-shell -q icyleaf.workspaces moveSpecial silent")
o.bind("SUPER + ALT + S", "Special scratchpad picker", "omarchy-shell -q icyleaf.workspaces selectSpecial")

-- Multi-monitor numbered workspaces switching
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  hl.unbind("SUPER + SHIFT + CTRL + " .. key)

  -- Switch to slot on the focused monitor
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces focus " .. workspace)

  -- Move focused window to slot and follow
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces move " .. workspace)

  -- Move focused window to slot silently
  o.bind("SUPER + SHIFT + CTRL + " .. key, "Move window silently to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces movesilent " .. workspace)
end
```

Then reload Hyprland:
```bash
hyprctl reload
```

---

## IPC Protocol

The plugin listens on the IPC target `icyleaf.workspaces` via `omarchy-shell`:

| Method | Arguments | Description |
| :--- | :--- | :--- |
| `focus` | `<slot: 1-10>` | Switches to workspace slot `<slot>` on the currently focused monitor |
| `move` | `<slot: 1-10>` | Moves the active window to slot `<slot>` on the focused monitor and follows |
| `movesilent` | `<slot: 1-10>` | Moves the active window to slot `<slot>` on the focused monitor silently |
| `toggleSpecial` | `<name: string>` | Toggles special workspace `special:<name>` |
| `moveSpecial` | `<name: string>` | Moves active window into `special:<name>` silently |
| `moveSpecialFollow`| `<name: string>` | Moves active window into `special:<name>` and follows |
| `selectSpecial` | *(none)* | Toggles the Special Scratchpads Quick Picker Overlay |
| `preview` | *(none)* | Summons the Per-Monitor Layout Preview Overlay on the currently focused monitor |

### CLI Example
```bash
# Switch to slot 2 on the currently active monitor
omarchy-shell icyleaf.workspaces focus 2

# Toggle special scratchpad 'term'
omarchy-shell icyleaf.workspaces toggleSpecial term

# Open Special Scratchpad Picker Overlay
omarchy-shell icyleaf.workspaces selectSpecial

# Open the Monitor Layout Preview on the focused display
omarchy-shell icyleaf.workspaces preview
```

---

## Credits

The per-workspace app icon feature (GUI/TUI icon resolution and the process-tree probe) is inspired by [skylightlim/omarchy-workspace-peek](https://github.com/skylightlim/omarchy-workspace-peek) (MIT). Its code is referenced for approach, not copied, and this plugin does not depend on it to load.
