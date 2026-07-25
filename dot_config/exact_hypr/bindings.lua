-- Personal keybindings overrides
-- Loaded after Omarchy's defaults to allow customization and unbinding.

-- 1. Unbind defaults we want to override
hl.unbind("SUPER + B")
hl.unbind("SUPER + F")
hl.unbind("SUPER + T")
hl.unbind("SUPER + E")
hl.unbind("SUPER + D")
hl.unbind("SUPER + W")
hl.unbind("SUPER + P")
hl.unbind("SUPER + L")
hl.unbind("SUPER + S")
hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + ALT + D")
hl.unbind("SUPER + F1")
hl.unbind("SUPER + slash")
hl.unbind("SUPER + PRINT")
hl.unbind("SUPER + SHIFT + PRINT")
hl.unbind("SUPER + CTRL + PRINT")
hl.unbind("SUPER + ALT + PRINT")
hl.unbind("SUPER + SHIFT + V")
hl.unbind("SUPER + CTRL + V")
hl.unbind("SUPER + COMMA")
hl.unbind("SUPER + CTRL + PERIOD")
hl.unbind("SUPER + SHIFT + R")
hl.unbind("SUPER + SHIFT + ALT + R")
hl.unbind("SUPER + SHIFT + CTRL + R")
hl.unbind("SUPER + CTRL + ALT + B")
hl.unbind("SUPER + CTRL + ALT + W")
hl.unbind("SUPER + SHIFT + B")
hl.unbind("CTRL + ALT + DELETE")
hl.unbind("SUPER + U")

-- 2. Bind personal customized keys (Option A - custom apps & wrappers)
o.bind("SUPER + SHIFT + T", "Tmux", "uwsm-app -- xdg-terminal-exec --dir=\"$(icy-cmd-terminal-cwd)\" tmux new")
o.bind("SUPER + T", "Terminal", "uwsm-app -- xdg-terminal-exec --dir=\"$(icy-cmd-terminal-cwd)\"")
o.bind("SUPER + B", "Browser", "icy-launch-browser")
o.bind("SUPER + F", "File manager", "nemo")
o.bind("SUPER + E", "Editor", "code")
o.bind("SUPER + D", "discord", "vesktop")
o.bind("SUPER + L", "Lock screen", "hyprlock")
o.bind("SUPER + SHIFT + L", "Sleep", "hyprctl dispatch dpms off")
o.bind("SUPER + ALT + D", "Docker", "icy-launch-tui lazydocker")
o.bind("SUPER + F1", "Activity", "icy-launch-tui btop")
o.bind("SUPER + slash", "Passwords", "uwsm app -- flatpak run com.bitwarden.desktop")

-- Captures
o.bind("SUPER + PRINT", "Screenshot with editing", "icy-cmd-screenshot")
o.bind("SUPER + SHIFT + PRINT", "Screenshot to clipboard", "icy-cmd-screenshot smart clipboard")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "icy-capture-text")
o.bind("SUPER + ALT + PRINT", "Screen record a region", "icy-menu screenrecord")

-- Clipboard manager
o.bind("SUPER + SHIFT + V", "Clipboard", "icy-launch-walker -m clipboard")
o.bind("SUPER + CTRL + V", "Clipboard manager", "icy-launch-walker -m clipboard")

-- Notifications
o.bind("SUPER + COMMA", "Notifications", "swaync-client -t -sw")

-- Transcoding
o.bind("SUPER + CTRL + PERIOD", "Transcode", "icy-transcode")

-- Reminders
o.bind("SUPER + SHIFT + R", "Set reminder", "icy-menu reminder-set")
o.bind("SUPER + SHIFT + ALT + R", "Show reminders", "icy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "icy-reminder clear")

-- Waybar-less info
o.bind("SUPER + CTRL + ALT + T", "Show time", o.notify("    $(date +\"%A %H:%M  ·  %d %B %Y  ·  Week %V\")"))
o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", o.notify("$(icy-battery-status)"))
o.bind("SUPER + CTRL + ALT + W", "Show weather", o.notify("$(icy-weather-status)"))

-- Web apps
o.bind("SUPER + SHIFT + B", "BiliBili", "icy-launch-webapp \"https://www.bilibili.com/\"")

-- System window management
o.bind("CTRL + ALT + DELETE", "Close all Windows", "icy-cmd-close-all-windows")
o.bind("SUPER + W", "Close active window", hl.dsp.window.close())
o.bind("SUPER + U", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())

-- Mouse binds
hl.config({
  bindm = {
    "SUPER, mouse:272, movewindow",
    "SUPER, mouse:273, resizewindow",
    "SUPER, Z, movewindow",
    "SUPER, X, resizewindow",
  }
})
