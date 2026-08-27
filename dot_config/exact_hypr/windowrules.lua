-- Personal window rules overrides

-- Evince PDF viewer fullscreen override
o.window("org.gnome.Evince", { fullscreen = false })

-- WeChat popups focus fix
-- o.window({ class = "wechat", float = true }, { stay_focused = true })
o.window({ class = "(wechat|Wechat)", title = "(Moments)" }, { float = true, center = true })

-- App work-spaces mapping
o.window("org.telegram.desktop", { workspace = "9" })
o.window("wechat", { workspace = "9" })
o.window("discord", { workspace = "10" })
o.window("vesktop", { workspace = "10" })

-- omarchy plugins ruls

-- plugin: ryuhzk.simfarm
o.window({ class = "^chrome-.*__-Simfarm$" }, {
  float = true,
  center = true,
  size = { 600, 1040 },
})

o.window({ class = "org.quickshell", title = "(MODICT)" }, { float = true, center = true })
