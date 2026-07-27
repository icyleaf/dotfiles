# Local Clock Omarchy Plugin

Third-party clone of `omarchy.clock` with a calendar popup.

Install it at:

```text
~/.config/omarchy/plugins/local.clock/
```

Then run:

```bash
omarchy plugin rescan
omarchy plugin enable local.clock
```

Add it to the bar from `local.settings` or with:

```bash
omarchy plugin bar add local.clock
```

Interactions:

- left click opens the month calendar
- middle click toggles the alternate clock format
- right click opens the Omarchy timezone menu
- hover reveals a small settings button on the left when enabled

Configurable options:

- `format`
- `formatAlt`
- `verticalFormat`
- `showSettingsGear`
- `firstDayOfWeek`: `sunday` or `monday`
- `settingsCommand`
