-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
local home = os.getenv("HOME")
local omarchy_path = os.getenv("OMARCHY_PATH") or (home .. "/.local/share/omarchy")
dofile(omarchy_path .. "/default/hypr/bootstrap.lua")

-- Ensure modules resolve from the computed Omarchy path even if OMARCHY_PATH is
-- missing from the launcher environment.
-- package.path = home
--   .. "/.local/state/?.lua;"
--   .. home
--   .. "/.config/?.lua;"
--   .. omarchy_path
--   .. "/?.lua;"
--   .. package.path

-- package.preload["default.hypr.paths"] = function()
--   return {
--     home = home,
--     config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config"),
--     state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state"),
--     omarchy_path = omarchy_path,
--   }
-- end

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false

-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- -- keeping core window-manager bindings:
omarchy_preinstalled_bindings = false

-- -- Load Omarchy defaults.
require("default.hypr.omarchy")

-- -- Put your personal overrides in these files. They're loaded after Omarchy's
-- -- defaults so package updates can improve the defaults without rewriting your
-- -- ~/.config/hypr files.
require("hypr.envs")
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.windowrules")

-- Toggle config flags dynamically.
require("default.hypr.toggles")
