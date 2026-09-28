-- Personal monitors configuration

-- Omarchy clamshell recovery reads this value for internal display rescale.
local omarchy_monitor_scale = 1.8

-- Internal display / eDP-1 (Noneed changes)
hl.monitor({
  output = "desc:Tianma Microelectronics Ltd. TL140ADXP24-0",
  mode = "2880x1800@120",
  position = "0x0",
  scale = omarchy_monitor_scale
})

-- ## Home (SET 1)
-- #              ┌───────────────────┐
-- #              │                   │
-- #              │  HS 140KP (ID 1)  │
-- #              │                   │
-- #  ┌───────────└───────────────────┘──────┐
-- #  │                      │               │
-- #  │                      │  eDP-1 (ID 0) │
-- #  │     LG 4K (ID 2)     │               │
-- #  │                      │───────────────┘
-- #  │                      │
-- #  └──────────────────────┘

-- ## Home (SET 2)
-- # ┌──────────────────────┌──────────────────────┌───────────────┐
-- # │                      │                      │               │
-- # │                      │                      │     eDP-1     │
-- # │      LG 4K (2)       │       LG 4K (1)      │               │
-- # │                      │                      └───────────────┘
-- # │                      │                      │
-- # │                      │                      │
-- # └──────────────────────└──────────────────────┘

-- ## Tokyo
-- #         ┌──────────────────┐
-- #         │                  │
-- #         │                  │
-- #         │     16:10 DIY    │
-- #         │                  │
-- #         │                  │
-- # ┌───────┴───────────┌────────────────┐
-- # │                   │                │
-- # │                   │                │
-- # │  HS 140KP (ID 1)  │  eDP-1 (ID 0)  │
-- # │                   │                │
-- # │                   │                │
-- # └───────────────────└────────────────┘

-- -- 2. Home displays (LG 4K)
-- hl.monitor({
--   output = "desc:LG Electronics LG HDR 4K 0x0000323A",
--   mode = "3840x2160@30",
--   position = "-2560x0",
--   scale = 1.5
-- })

-- hl.monitor({
--   output = "desc:LG Electronics LG HDR 4K 0x0001C243",
--   mode = "3840x2160@60",
--   position = "-5120x0",
--   scale = 1.5
-- })

-- 3. Tokyo/Work displays
hl.monitor({
  output = "desc:YTH HS-140KP",
  mode = "3840x2160@60",
  position = "auto-left",
  scale = 2
})

hl.monitor({
  output = "desc:Invalid Vendor Codename - RTK UHD demoset-1",
  mode = "3240x2160@60",
  position = "auto-center-up",
  scale = 2
})

-- ## 16:10 monitor for work
-- monitor = desc:Invalid Vendor Codename - RTK UHD, 3240x2160@60, -400x-1080, 2

-- monitor = desc:YTH HS-140KP, 3840x2160@60, -1980x0, 2



-- -- 4. Workspace rules
-- hl.workspace_rule({ workspace = "1", name = "Main", monitor = "eDP-1", default = true })
-- hl.workspace_rule({ workspace = "21", name = "Browser", monitor = "desc:YTH HS-140KP", default = true })
