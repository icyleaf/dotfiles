-- Personal window rules overrides

-- Evince PDF viewer fullscreen override
o.window("org.gnome.Evince", { fullscreen = false })

-- App work-spaces mapping
o.window("org.telegram.desktop", { workspace = "9" })
o.window("wechat", { workspace = "9" })
o.window("discord", { workspace = "10" })
o.window("vesktop", { workspace = "10" })

-- WeChat popups focus fix
o.window({ class = "wechat", float = true }, { stay_focused = true })

-- Terminal monitoring tools floats
o.window({ tag = "terminal", title = "top" }, { float = true })
o.window({ tag = "terminal", title = "btop" }, { float = true })
o.window({ tag = "terminal", title = "htop" }, { float = true })

-- Bitwarden default size
o.window("Bitwarden", { size = { 500, 900 } })
