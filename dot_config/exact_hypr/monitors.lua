-- Personal monitors configuration

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Internal display / eDP-1
hl.monitor({
  output = "desc:Tianma Microelectronics Ltd. TL140ADXP24-0",
  mode = "2880x1800@120",
  position = "0x0",
  scale = 1.6
})

-- External display / DP-2 (LG 4K 1)
hl.monitor({
  output = "desc:LG Electronics LG HDR 4K 0x0000323A",
  mode = "3840x2160@30",
  position = "-2560x0",
  scale = 1.5
})

-- External display / (LG 4K 2)
hl.monitor({
  output = "desc:LG Electronics LG HDR 4K 0x0001C243",
  mode = "3840x2160@60",
  position = "-5120x0",
  scale = 1.5
})
