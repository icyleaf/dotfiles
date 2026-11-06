-- Personal keybindings overrides
-- Loaded after Omarchy's defaults to allow customization and unbinding.

-- 1. Unbind defaults we do not replace with a Hyprland action (handed to apps / Fcitx5 / disabled)
hl.unbind("CTRL + SPACE")
hl.unbind("CTRL + ENTER")
hl.unbind("PRINT")
hl.unbind("SUPER + Q")            -- Keep SUPER + W as our only close-window key
hl.unbind("SUPER + M")            -- No dock, unbind minimize
hl.unbind("SUPER + A")            -- Disable macOS-style Super+A select all (use Ctrl+A)
hl.unbind("SUPER + grave")        -- Disable qconsole dropdown overlay
hl.unbind("SUPER + SHIFT + grave")
hl.unbind("SUPER + SHIFT + Q")    -- Disable omacalc (use icyleaf.qalculator via SUPER + =)
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + SHIFT + PRINT")
hl.unbind("SUPER + CTRL + V")
hl.unbind("SUPER + CTRL + ALT + B")
hl.unbind("SUPER + CTRL + ALT + W")
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + CTRL + S")

-- 2. Personal customized keys (using o.rebind to replace Omarchy defaults cleanly)
o.rebind("SUPER + T", "Terminal", "uwsm-app -- xdg-terminal-exec --dir=\"$(icy-cmd-terminal-cwd)\"")
o.rebind("SUPER + B", "Browser", "icy-launch-browser")
o.rebind("SUPER + F", "File manager", "icy-file-manager")
o.rebind("SUPER + E", "Editor", "code")
o.rebind("SUPER + D", "discord", "vesktop")
o.rebind("SUPER + L", "Lock screen", "icy-system-lock")
o.bind("SUPER + SHIFT + L", "Sleep", function()
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = "disable" }))
    end, {timeout = 500, type = "oneshot"})
  end)
o.bind("SUPER + SHIFT + P", "Orbit Quick Launcher", "omarchy-shell shell toggle local.orbit")
o.rebind("SUPER + ALT + D", "Docker",  "icy-launch-tui lazydocker")
o.rebind("SUPER + F1", "Activity", "icy-launch-tui btop")
o.bind("SUPER + F2", "System Monitor", "omarchy-shell icyleaf.resources toggle")
o.rebind("SUPER + slash", "Passwords", "uwsm app -- flatpak run com.bitwarden.desktop")

-- Qalculator overlay (Raycast-style). SUPER + = is the unbound code:21.
o.rebind("SUPER + code:21", "Qalculator", "omarchy-shell shell toggle icyleaf.qalculator")

-- Captures
o.rebind("SUPER + PRINT", "Screenshot with editing", "icy-capture-screenshot")
o.rebind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "icy-capture-text")
o.rebind("SUPER + ALT + PRINT", "Screenrecording", "icy-capture-screenrecording")

-- Clipboard manager
o.rebind("SUPER + SHIFT + V", "Clipboard", "icy-clipboard")

-- Transcoding
o.rebind("SUPER + CTRL + PERIOD", "Transcode", "icy-transcode")

-- Reminders
o.rebind("SUPER + SHIFT + R", "Set reminder", "icy-menu reminder-set")
o.rebind("SUPER + SHIFT + ALT + R", "Show reminders", "icy-reminder show")
o.rebind("SUPER + SHIFT + CTRL + R", "Clear reminders", "icy-reminder clear")

-- Localsend share
o.bind("SUPER + SHIFT + O", "Share", "omarchy-menu toggle share")

-- System window management
o.rebind("CTRL + ALT + DELETE", "Close all Windows", "icy-cmd-close-all-windows")
o.rebind("SUPER + W", "Close active window", hl.dsp.window.close())
o.rebind("SUPER + U", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
o.rebind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())

-- Mouse binds
o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
o.bind("SUPER + Z", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + X", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Custom special workspaces switching (Scratchpads via icyleaf.workspaces IPC)
o.rebind("SUPER + S", "Toggle silent scratchpad", "omarchy-shell -q icyleaf.workspaces toggleSpecial silent")
o.rebind("SUPER + SHIFT + S", "Move window to silent scratchpad", "omarchy-shell -q icyleaf.workspaces moveSpecial silent")
o.rebind("SUPER + ALT + S", "Special scratchpad picker", "omarchy-shell -q icyleaf.workspaces selectSpecial")

-- Custom numbered workspaces switching (delegated to icyleaf.workspaces plugin via IPC)
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces focus " .. workspace)
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces move " .. workspace)
  o.rebind("SUPER + SHIFT + CTRL + " .. key, "Move window silently to workspace " .. workspace, "omarchy-shell -q icyleaf.workspaces movesilent " .. workspace)
end

-- omarchy plugins
o.bind("SUPER + SHIFT + D", "Dict", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell toggle icyleaf.modict"))
end)

o.bind("SUPER + ALT + P", "Input Fusion", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell toggle icyleaf.input-fusion"))
end)

o.bind("SUPER + SHIFT + W", "Mirador", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell summon mirador '{}'"))
end)

o.rebind("SUPER + comma", "Bitwarden", function()
  hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell toggle icyleaf.bitwarden"))
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

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
