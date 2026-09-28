-- Personal window rules overrides

-- Evince PDF viewer fullscreen override
o.window("org.gnome.Evince", { fullscreen = false })

-- WeChat popups focus fix
-- o.window({ class = "wechat", float = true }, { stay_focused = true })
o.window({ class = "(wechat|Wechat)", title = "(Moments)" }, { float = true, center = true })
o.window({ class = "(wechat|Wechat)", title = "(Photos and Videos)" }, { float = true, fullscreen = true })

-- App-to-workspace routing now lives in the icyleaf.workspaces plugin's
-- monitor-aware Workspace Bindings (see CONTEXT.md). Author them per machine
-- profile in .chezmoitemplates/workspace-bindings.<profile>.json; the plugin
-- routes windows on open, so no static `workspace` rules are needed here.

-- omarchy plugins ruls

-- plugin: ryuhzk.simfarm
o.window({ class = "^chrome-.*__-Simfarm$" }, {
  float = true,
  center = true,
  size = { 600, 1040 },
})

o.window({ class = "org.quickshell", title = "(MODICT)" }, { float = true, center = true })
o.window({ class = "org.quickshell", title = "(Bitwarden)" }, {
  float = true,
  center = true,
  size = { 1152, 768 }
})
