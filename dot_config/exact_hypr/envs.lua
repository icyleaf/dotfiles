-- Scaling
hl.env("GDK_SCALE", "1.6")
hl.env("QT_SCALE_FACTOR", "1.6")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1.6")

hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")