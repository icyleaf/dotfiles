# Calculator (`icyleaf.calculator`)

A Raycast-style quick calculator overlay for [Omarchy](https://github.com/omarchy/omarchy). Press the hotkey, type an expression, watch the answer appear live, press `Enter` to copy it and get out of the way.

---

## What it does

- **Live evaluation** — the answer appears as you type (150 ms debounce). The evaluation gate suppresses qalc's partial echoes, so typing `1 +` never shows a misleading `1`.
- **Full qalc reach** — arithmetic, powers, functions, unit conversion, and currency (`2+2`, `sqrt(625)`, `29 inches to cm`, `10 usd in gbp`). Offline; qalc uses its cached exchange rates.
- **Copy on Enter** — `Enter` copies the answer to the clipboard and closes. `Alt+Enter` copies and keeps the overlay open for the next calculation.
- **Persistent history** — the last 50 successful expressions, newest first. With an empty input the history list shows; `↑`/`↓` browse it and `Enter` copies an entry. Re-computing an expression moves it to the top instead of duplicating it.
- **Built-in help** — `Ctrl+/` swaps the history area for a syntax reference (math, percent, conversions, currency, keys), and swaps back. The help content lives in `CalcModel.js`, so it is covered by the test suite.
- **Focused-monitor overlay** — a fullscreen `PanelWindow` on the focused output, matching the emojis and clipboard overlays.
- **No qalc?** — the card says so instead of failing silently. Nothing else degrades.

## Usage

| Key | Action |
|-----|--------|
| `SUPER + =` | Toggle the overlay |
| type | Evaluate live |
| `Enter` | Copy the answer, close |
| `Alt + Enter` | Copy the answer, stay open |
| `↑` / `↓` | Browse history (empty input) |
| `Ctrl + /` | Toggle the syntax help (empty input) |
| `Esc` | Close |

Conversions use qalc's `to` keyword (`10 usd to gbp`, `29 inches to cm`). qalc reads `in` as the inch unit, so `10 usd in gbp` is **not** a conversion — the help lists `to` examples only.

## Deployment

Managed via [Chezmoi](https://chezmoi.io) within `dot_config/omarchy/plugins/icyleaf.calculator`. The plugin is enabled in `dot_config/omarchy/private_shell.json` and the hotkey is bound in `dot_config/exact_hypr/bindings.lua`.

```bash
chezmoi apply
omarchy-restart-shell
```

`SUPER + =` is delivered as `code:21` (the `=` key without Shift). Omarchy's default `SUPER + =` is the tiling action "Shrink window left", so `bindings.lua` unbinds `SUPER + code:21` before rebinding it. The Shift/Alt/Ctrl resize variants are left intact.

## Requirements

- `qalc` (Arch: the `libqalculate` package) on `PATH`. Currency conversion uses qalc's cached rates; no network call is made by this plugin.
- Wayland clipboard tooling (`wl-copy`, part of `wl-clipboard`) for the copy action.

## Architecture

- `manifest.json` — `kinds: ["overlay"]`, `activation: "on-demand"`, `keepLoaded: true`.
- `Calculator.qml` — the overlay: input, live answer, history list, qalc process, clipboard process.
- `CalcModel.js` — the pure-JS seam: history parsing/dedup/capping, result cleaning, and the evaluation gate, plus the help reference data. Covered by `tests/tst_calcmodel.qml`.
- History lives at `~/.local/state/omarchy/calculator-history.json`, written atomically on commit only.

### Tests

```bash
cd dot_config/omarchy/plugins/icyleaf.calculator/tests
qmltestrunner -input tst_calcmodel.qml
```
