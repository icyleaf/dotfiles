# Local Orbit

Orbit is an Omarchy shell overlay plugin for cursor-centered radial menus. It opens a ring at the cursor, highlights the slice you move toward, and can activate that slice when you release the bound mouse button.

## Install

```bash
omarchy plugin add local.orbit --enable
omarchy restart shell
```

## Requirements

- `hyprctl` and `omarchy-shell`
- `wev` for button sniffing
- Python `evdev` module for physical-button release detection used by `orbit-press.sh --button <code>`

## Try it

```bash
~/.config/omarchy/plugins/local.orbit/scripts/orbit-press.sh
```

Move toward a slice and click it, or press `Esc` to close.

## Bind a mouse button

First sniff the button code:

```bash
~/.config/omarchy/plugins/local.orbit/scripts/sniff-button.sh
```

For a Logitech back/thumb button this is usually `mouse:275` (`BTN_SIDE`), but sniff it because Logitech devices can expose extra buttons differently.

Add the binding to `~/.config/hypr/bindings.lua`:

```lua
o.bind("mouse:275", "Orbit press", "~/.config/omarchy/plugins/local.orbit/scripts/orbit-press.sh --button 275", { locked = true })
o.bind("mouse:275", "Orbit release fallback", "~/.config/omarchy/plugins/local.orbit/scripts/orbit-release.sh", { locked = true, release = true })
```

Then validate/reload Hyprland:

```bash
hyprctl reload
hyprctl configerrors
```

If your sniffed token is not `mouse:275`, replace both occurrences.

## Configure rings

Orbit reads `~/.config/omarchy/local.orbit.json`. If the file does not exist, it uses the built-in default rings.

The bundled default/example includes:

- `main`: Launcher, Dictation, Clipboard, Dev, Screenshot, Window, Back, Emoji
- `window`: float, fullscreen, close, scratchpad, move-to-scratchpad, previous/next workspace
- `dev`: terminal, editor, files, model usage, bar settings, restart shell, reload Hyprland

Start from the example:

```bash
cp ~/.config/omarchy/plugins/local.orbit/config.example.json ~/.config/omarchy/local.orbit.json
```

Minimal shape:

```json
{
  "defaultRing": "main",
  "rings": [
    {
      "id": "main",
      "label": "Orbit",
      "actions": [
        { "label": "Launcher", "icon": "󰍉", "command": "omarchy-shell shell toggle omarchy.launcher '{}'" },
        { "label": "Dev", "icon": "", "ring": "dev" }
      ]
    },
    {
      "id": "dev",
      "label": "Dev",
      "actions": [
        { "label": "Main", "icon": "󰁍", "ring": "main" },
        { "label": "Restart Shell", "icon": "", "command": "omarchy restart shell" }
      ]
    }
  ]
}
```

Action fields:

- `label`: text shown on the slice.
- `icon`: a Nerd Font glyph or short label.
- `command`: shell command executed via `bash -lc`.
- `argv`: optional command array executed directly, e.g. `["uwsm-app", "--", "nautilus"]`.
- `ring`: switch to another ring instead of launching.
- `close`: close without launching.

The file is watched, so edits apply without restarting the shell.

## IPC

```bash
omarchy-shell shell summon local.orbit '{"mode":"click"}'
omarchy-shell shell call local.orbit release ""
omarchy-shell local.orbit state
```

`orbit-press.sh` passes cursor coordinates from `hyprctl cursorpos` so the ring appears under the pointer.
