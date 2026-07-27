-- Personal autostart applications override

hl.on("hyprland.start", function()
  -- User specific autostart applications
  -- hl.exec_cmd(o.launch("hypridle"))                              -- Idle management
  -- hl.exec_cmd(o.launch("waybar"))                                -- Status bar
  hl.exec_cmd(o.launch("wl-gammarelay-rs run"))                  -- Per-monitor software brightness
  hl.exec_cmd(o.launch("hypr-input-switcher -w"))                -- Input switch notification
  hl.exec_cmd(o.launch("synology-drive"))                        -- Synology Drive
  hl.exec_cmd(o.launch("keyd-application-mapper"))               -- Start keyd for app remapping
  hl.exec_cmd(o.launch("swaync"))                                -- Notification panel daemon
  hl.exec_cmd(o.launch("udiskie --no-automount --smart-tray"))   -- Automount drives with tray icon

  -- Clipboard history (better than walker built-in clipboard module)
  -- hl.exec_cmd("wl-paste --type text --watch cliphist store")
  -- hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
