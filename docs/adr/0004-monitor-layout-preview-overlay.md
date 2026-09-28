# ADR-0004: Per-Monitor Layout Preview Overlay in `icyleaf.workspaces`

**Status**: Accepted  
**Date**: 2026-09-07

## Context

The desktop drives three physical monitors through the Monitor-Anchored Workspace Model in the `icyleaf.workspaces` bar widget (see CONTEXT.md). Each monitor's status bar shows its own 10-slot workspace set and a Monitor Identity Badge (`󰹍 M1`...). Two gaps remain in daily spatial awareness:

1. **No cross-screen occupancy overview.** The bar on one monitor only shows that monitor's own 10 slots; the state of the other monitors' workspaces is invisible until you look at their bars.
2. **No per-monitor spatial preview.** The existing overview tool (Mirador, `SUPER+SHIFT+W`) flattens workspaces into a one-dimensional grid and does not convey what each display's active workspace looks like at a glance.

Three presentation approaches were considered for showing the layout:

1. **True-coordinate fit** — cards placed at the monitors' literal global x/y coordinates, uniformly scaled to fit the screen. This is the most literal but scatters cards when panels report far-apart (or exactly 0px-touching) logical positions, leaving large empty areas.
2. **Anchor-centered** — the clicked/focused monitor blown up to fill the screen with the others clipped around it. Hides the other displays entirely on typical top/bottom arrangements.
3. **Compact pack** — each monitor keeps its true aspect ratio, but panels whose vertical spans overlap are grouped into rows (true left→right order and stagger preserved), rows stack by true top→bottom order, and the whole block is uniformly scaled to fit and centered.

## Decision

Extend the `icyleaf.workspaces` bar widget with a read-only **Per-Monitor Layout Preview Overlay** using the **compact pack** (approach 3), without adding a new plugin and without duplicating Mirador's interactive window management.

### Trigger and lifecycle

- **Right-click** on a Monitor Identity Badge opens the overlay on that badge's screen; left-click keeps its existing focus-monitor behavior (the badge press handler branches on the mouse button).
- Each per-monitor widget instance hosts its own full-screen `PanelWindow` overlay (the pattern already proven by this widget's special-picker overlay: `ExclusionMode.Ignore`, WlrLayershell `Overlay`, exclusive keyboard focus while open), anchored to the bar surface it lives on — so the overlay appears on the monitor whose badge was clicked.
- **Single overlay invariant**: opening on one monitor broadcasts a close to every other instance's overlay first. Because an open overlay covers only its own screen, a badge on any other monitor stays reachable; right-clicking it closes the remote overlay and opens one on that monitor instead. Re-right-clicking a covered badge lands on the overlay surface, which dismisses on right-click — yielding the toggle gesture.
- A no-argument IPC method `preview` summons the overlay for the globally focused monitor (it broadcasts so the instance hosting the focused monitor's bar opens). No shell.json setting or Hyprland keybinding is added now.

### Content of the overlay

- **Cards**: every enabled, non-mirrored physical monitor as a card preserving its true aspect ratio, packed into rows and fit+centered as described above.
- **Card header**: a compact pill (top-center) showing the monitor badge (`M<n>`), connector name, and physical resolution `WxH@scale`; the full connector description appears on hover. The display holding global focus is highlighted (accent border + pill tint).
- **Occupancy strip**: a fixed 10-slot strip per monitor (slots map to that monitor's offset workspace IDs; slot 10 renders as `0`), with occupied slots lit, the active slot accented, and the globally focused workspace outlined. A workspace counts as occupied only when it actually holds windows, so an idle active workspace renders as empty.
- **Body**: the active workspace's windows drawn as rectangles at their true relative geometry within each card — tiled and floating windows, fullscreen fills the card, Hyprland groups collapsed to a single frame with a member count. Rectangles smaller than a readable minimum are expanded around their center. No screenshots.
- **Empty active workspace**: the card is still drawn (header + occupancy strip), showing the display is present but idle.

### Interaction

- **Read-only.** No dragging, no window activation, no workspace switching — Mirador already owns interactive window management; this overlay answers "what is where", not "change it".
- Clicking a card **focuses that monitor and closes** the overlay; clicking empty overlay space or pressing `Esc` closes; arrow keys move the selection between cards and `Return` focuses the selected monitor and closes.

### Refresh

- Event-driven only while open: on Hyprland `rawEvent` for `monitor*`, `workspace*`, `window*`, `group*`, `fullscreen`, `changefloatingmode`, and `focusedmon`, refresh monitors/workspaces/toplevels and recompute. Opening refreshes once.

## Reasons

- **Compact pack over true coordinates**: the user evaluated both renders; literal coordinates left the three monitors scattered across the corners with large dead space because real panels report wide logical gaps, while the compact pack keeps every display fully visible, correctly ordered, and readable.
- **Inside the existing widget**: the widget already owns the full-screen overlay pattern (special picker), the per-monitor bar instances, and the Direct Hyprland IPC Dispatch seam, so no cross-plugin summon plumbing or new process is required.
- **Pure-JS geometry seam**: the layout math is extracted into a `.pragma library` module (following the Mirador house style) and is covered by fixture contract tests; the QML shells stay thin.

## Trade-offs Accepted

- The overlay is not a literal spatial map of the physical desktop: gaps between panels are normalized to a small visual gap so panels read as distinct surfaces. For a purely cosmetic overview this is acceptable; Mirador-style literal geometry was rejected by the user as too sparse.
- Window projection, group collapsing, and event-name whitelisting re-express logic that Mirador also implements (two independent implementations of the same concepts live in the desktop). Mirador is a third-party external pinned by Chezmoi and MIT-licensed; its code is referenced for approach, not copied, and this widget must not depend on Mirador's internals to load.
- Group collapsing uses a minimal union–find over grouped-window addresses; the geometry seam is tested in isolation with plain-data fixtures, and live behavior is verified empirically on the real three-monitor desktop.
