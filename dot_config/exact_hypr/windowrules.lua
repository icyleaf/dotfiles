-- Personal window rules overrides

-- Evince PDF viewer fullscreen override
o.window("org.gnome.Evince", { fullscreen = false })

-- WeChat popups focus fix
-- o.window({ class = "wechat", float = true }, { stay_focused = true })
o.window({ class = "(wechat|Wechat)", title = "(Moments)" }, { float = true, center = true })
o.window({ class = "(wechat|Wechat)", title = "(Photos and Videos)" }, { float = true, fullscreen = true })

-- App work-spaces mapping
o.window("org.telegram.desktop", { workspace = "9" })
o.window("wechat", { workspace = "9" })
o.window("discord", { workspace = "10" })
o.window("vesktop", { workspace = "10" })

-- LINE is a Chrome webapp whose real title ("LINE") is only set after the
-- window is created. Static effects like `workspace` are evaluated against the
-- initial title, which is the extension id, so a window rule cannot catch it.
-- Instead move it once the title event reports the settled title.
local line_placed = {}
hl.on("window.title", function(w)
  if w == nil or w.class == nil or w.title == nil then
    return
  end
  if line_placed[w.address] then
    return
  end
  if w.class:match("^chrome-") and w.title:match("(LINE|Line)") then
    line_placed[w.address] = true
    hl.dispatch(hl.dsp.window.move({ workspace = "8", window = w }))
  end
end)

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
