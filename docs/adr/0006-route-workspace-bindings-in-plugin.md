# ADR-0006: Route Workspace Bindings in `icyleaf.workspaces`, Not via Generated Hyprland Rules

**Status**: Accepted  
**Date**: 2026-09-28

## Context

App→workspace routing used to be hardcoded `workspace` window rules in
`windowrules.lua`, which only express a global workspace number and cannot pick
a target by monitor. The comparable third-party plugin
(`Loedn/omarchy-workspace-router`) instead generates static Hyprland Lua rules
(`o.window({ initial_class = [[^class$]] }, { workspace = "N" })`) and injects a
`require("hypr.workspace-apps")` line into `hyprland.lua`.

Static rules cannot resolve a target monitor at runtime (Hyprland's Lua config
has no reliable way to enumerate monitor descriptions), cannot defer a decision
until a window title settles, and pull a second generated file into
`~/.config/hypr/`.

## Decision

Implement routing inside the `icyleaf.workspaces` bar widget. A pure
`BindingModel` seam matches the window's initial class (optionally only once a
title regex settles), resolves a Monitor Matcher (`id`, connector `name`, or
monitor `desc`) against the live monitor list, and computes the global workspace
from the monitor's offset plus the slot. A single owner instance of the widget
subscribes to Hyprland window events and dispatches the move through the
widget's existing Direct Hyprland IPC Dispatch seam. Bindings are authored in a
Chezmoi-managed, per-profile source and rendered to
`~/.config/hypr/workspace-bindings.json`, which the widget hot-reloads. No
Hyprland Lua is generated and `hyprland.lua` is not mutated.

## Reasons

- **Monitor-aware targets**: the plugin already enumerates monitors with their
  `id`, connector `name`, and `description`; Hyprland's Lua configuration does
  not expose them reliably.
- **Title deferral**: a webapp whose real title arrives after creation can be
  held pending and re-checked, which a static rule cannot do.
- **One seam, already established**: routing logic joins `LayoutModel` and
  `AppIconModel` as a pure, fixture-tested JS module; the shell layer stays
  thin.
- **Single source of truth**: the mapping lives in the Chezmoi source per
  machine profile; there is no generated Hyprland file and no runtime rewrite
  of `hyprland.lua`.

## Trade-offs Accepted

- Routing depends on the running shell (the bar widget). If the shell is down,
  windows open unrouted.
- A move happens shortly after the window opens (one clients fetch), rather
  than synchronously at creation.
- The generated-Lua integration style of the reference plugin is declined; the
  per-profile source plus Chezmoi template replaces it.

## Supersedes

- The hardcoded app→workspace `workspace` rules and the `window.title` LINE
  handler previously in `windowrules.lua`.
