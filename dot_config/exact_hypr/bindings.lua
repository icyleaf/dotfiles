-- Personal keybindings overrides
-- Loaded after Omarchy's defaults to allow customization and unbinding.

-- 1. Unbind defaults we want to override
hl.unbind("SUPER + B")
hl.unbind("SUPER + S")
hl.unbind("SUPER + F")
hl.unbind("SUPER + T")
hl.unbind("SUPER + E")
hl.unbind("SUPER + D")
hl.unbind("SUPER + W")
hl.unbind("SUPER + P")
hl.unbind("SUPER + L")
hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + SHIFT + S")
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
hl.unbind("SUPER + CTRL + S")
hl.unbind("CTRL + ALT + DELETE")
hl.unbind("SUPER + U")
hl.unbind("PRINT")

-- 2. Bind personal customized keys (Option A - custom apps & wrappers)
-- o.bind("SUPER + SHIFT + T", "Tmux", "uwsm-app -- xdg-terminal-exec --dir=\"$(icy-cmd-terminal-cwd)\" tmux new")
o.bind("SUPER + T", "Terminal", "uwsm-app -- xdg-terminal-exec --dir=\"$(icy-cmd-terminal-cwd)\"")
o.bind("SUPER + B", "Browser", "icy-launch-browser")
o.bind("SUPER + F", "File manager", "nemo")
o.bind("SUPER + E", "Editor", "code")
o.bind("SUPER + D", "discord", "vesktop")
o.bind("SUPER + L", "Lock screen", "hyprlock")
o.bind("SUPER + SHIFT + L", "Sleep", function()
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = "disable" }))
    end, {timeout = 500, type = "oneshot"})
  end)
o.bind("SUPER + SHIFT + P", "Orbit Quick Launcher", "omarchy-shell shell toggle local.orbit")
o.bind("SUPER + ALT + D", "Docker",  "icy-launch-tui lazydocker")
o.bind("SUPER + F1", "Activity", "icy-launch-tui btop")
o.bind("SUPER + F2", "System Monitor", "omarchy-shell icyleaf.resources toggle")
o.bind("SUPER + slash", "Passwords", "uwsm app -- flatpak run com.bitwarden.desktop")

-- Captures
o.bind("SUPER + PRINT", "Screenshot with editing", "icy-capture-screenshot")
-- o.bind("SUPER + SHIFT + PRINT", "Screenshot to clipboard", "icy-cmd-screenshot smart clipboard")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "icy-capture-text")
o.bind("SUPER + ALT + PRINT", "Screenrecording", "icy-capture-screenrecording")

-- Clipboard manager
o.bind("SUPER + SHIFT + V", "Clipboard", "icy-clipboard")

-- Notifications
-- o.bind("SUPER + COMMA", "Notifications", "swaync-client -t -sw")

-- Transcoding
o.bind("SUPER + CTRL + PERIOD", "Transcode", "icy-transcode")

-- Reminders
o.bind("SUPER + SHIFT + R", "Set reminder", "icy-menu reminder-set")
o.bind("SUPER + SHIFT + ALT + R", "Show reminders", "icy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "icy-reminder clear")

-- Localsend share
o.bind("SUPER + SHIFT + O", "Share", "omarchy-menu toggle share")

-- Waybar-less info
-- o.bind("SUPER + CTRL + ALT + T", "Show time", o.notify("    $(date +\"%A %H:%M  ·  %d %B %Y  ·  Week %V\")"))
-- o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", o.notify("$(icy-battery-status)"))
-- o.bind("SUPER + CTRL + ALT + W", "Show weather", o.notify("$(icy-weather-status)"))

-- System window management
o.bind("CTRL + ALT + DELETE", "Close all Windows", "icy-cmd-close-all-windows")
o.bind("SUPER + W", "Close active window", hl.dsp.window.close())
o.bind("SUPER + U", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())

-- Mouse binds
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
o.bind("SUPER + Z", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + X", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Custom workspaces switching (Independent workspaces per display)
o.bind("SUPER + S", "Toggle silent", hl.dsp.workspace.toggle_special("silent"))
o.bind("SUPER + SHIFT + S", "Move window to silent", hl.dsp.window.move({ workspace = "special:silent", follow = false }))

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)

  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, "bash /home/icyleaf/.config/hypr/scripts/workspace-switch.sh switch " .. workspace)
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, "bash /home/icyleaf/.config/hypr/scripts/workspace-switch.sh move " .. workspace)
  o.bind("SUPER + SHIFT + CTRL + " .. key, "Move window silently to workspace " .. workspace, "bash /home/icyleaf/.config/hypr/scripts/workspace-switch.sh movesilent " .. workspace)
end

-- omarchy plugins
o.bind("SUPER + SHIFT + D", "Dict", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell toggle icyleaf.modict"))
end)

o.bind("SUPER + ALT + P", "Hypr Input Swither", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell toggle icyleaf.hypr-input-switcher"))
end)

o.bind("SUPER + SHIFT + W", "Mirador", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell summon mirador '{}'"))
end)

hl.gesture({
  fingers = 3,
  direction = "up",
  action = function()
    hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell summon mirador '{}'"))
  end,
})

hl.gesture({
  fingers = 3,
  direction = "down",
  action = function()
    hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell hide mirador"))
  end,
})


o.bind("mouse:275", "Orbit press", "~/.config/omarchy/plugins/local.orbit/scripts/orbit-press.sh --button 275", { locked = true })
o.bind("mouse:275", "Orbit release fallback", "~/.config/omarchy/plugins/local.orbit/scripts/orbit-release.sh", { locked = true, release = true })
