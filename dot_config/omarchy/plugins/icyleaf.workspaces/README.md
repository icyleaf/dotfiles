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
