local Config = require('config')

return Config:init()
  :append(require('config.appearance'))
  :append(require('config.bindings'))
  :append(require('config.domains'))
  :append(require('config.fonts'))
  :append(require('config.general'))
  :append(require('config.launch')).options

-- local wezterm = require("wezterm")
-- local config = wezterm.config_builder()
-- local gpu_adapters = require('utils.gpu_adapter')
-- local platform = require('utils.platform')

-- local function resize_pane(key, direction)
--   return {
--     key = key,
--     action = wezterm.action.AdjustPaneSize { direction, 3 }
--   }
-- end

-- local function is_vim(pane)
--   local process_info = pane:get_foreground_process_info()
--   local process_name = process_info and process_info.name

--   return process_name == "nvim" or process_name == "vim"
-- end

-- local function find_vim_pane(tab)
--   for _, pane in ipairs(tab:panes()) do
--     if is_vim(pane) then
--       return pane
--     end
--   end
-- end

-- wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
--   local zoomed = ''
--   if tab.active_pane.is_zoomed then
--     zoomed = '[Z] '
--   end

--   local index = ''
--   if #tabs > 1 then
--     index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
--   end

--   return zoomed .. index .. tab.active_pane.title
-- end)

-- config.color_scheme = "Seti"
-- config.font = wezterm.font("MesloLGS Nerd Font Mono")
-- config.font_size = platform.is_mac and 12 or 18

-- config.enable_tab_bar = true
-- config.hide_tab_bar_if_only_one_tab = false
-- -- config.use_fancy_tab_bar = false
-- config.tab_max_width = 25
-- -- config.show_tab_index_in_tab_bar = false
-- config.switch_to_last_active_tab_when_closing_tab = true

-- config.window_decorations = "RESIZE"

-- config.window_background_opacity = 0.85
-- config.macos_window_background_blur = 10

-- config.window_frame = {
--   font = wezterm.font({ family = 'MesloLGS Nerd Font Mono', weight = 'Bold' }),
--   font_size = platform.is_mac and 12 or 18,
-- }

-- -- config.animation_fps = 60
-- -- config.max_fps = 120
-- config.front_end = 'WebGpu'
-- -- config.webgpu_power_preference = 'HighPerformance'
-- -- config.webgpu_preferred_adapter = gpu_adapters:pick_best()
-- if os.getenv("XDG_CURRENT_DESKTOP") == "Hyprland" then
--   config.enable_wayland = false
-- else
--   config.enable_wayland = true
-- end

-- -- config.debug_key_events = true
-- config.leader = { key = "j", mods = "CTRL|SHIFT", timeout_milliseconds = 1000 }
-- config.keys = {
--   -- split panes
--   {
--     key = 'd',
--     mods = 'SUPER',
--     action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
--   },
--   {
--     key = 'd',
--     mods = 'SUPER|SHIFT',
--     action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
--   },
--   {
--     key = 'w',
--     mods = 'SUPER',
--     action = wezterm.action.CloseCurrentPane { confirm = false },
--   },
--   -- move panes
--   {
--     key = 'h',
--     mods = 'SUPER|SHIFT',
--     action = wezterm.action.ActivatePaneDirection "Left",
--   },
--   {
--     key = 'j',
--     mods = 'SUPER|SHIFT',
--     action = wezterm.action.ActivatePaneDirection "Down",
--   },
--   {
--     key = 'k',
--     mods = 'SUPER|SHIFT',
--     action = wezterm.action.ActivatePaneDirection "Up",
--   },
--   {
--     key = 'l',
--     mods = 'SUPER|SHIFT',
--     action = wezterm.action.ActivatePaneDirection "Right",
--   },


--   -- { mods = "OPT", key = "LeftArrow", action = wezterm.action.SendKey({ mods = "ALT", key = "b" }) },
--   -- { mods = "OPT", key = "RightArrow", action = wezterm.action.SendKey({ mods = "ALT", key = "f" }) },
--   -- { mods = "CMD", key = "LeftArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "a" }) },
--   -- { mods = "CMD", key = "RightArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },
--   -- { mods = "CMD", key = "Backspace", action = wezterm.action.SendKey({ mods = "CTRL", key = "u" }) },

--   -- -- editor
--   -- {
--   --   key = 'a',
--   --   mods = "SUPER",
--   --   action = wezterm.action.SendKey({ mods = "CTRL", key = "a" })
--   -- },
--   -- {
--   --   mods = "SUPER", key = "RightArrow", action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },

--   -- {
--   --   key = 'a',
--   --   mods = 'CTRL',
--   --   action = wezterm.action.CopyMode 'MoveToStartOfLine',
--   -- },
--   -- {
--   --   key = 'e',
--   --   mods = 'CTRL',
--   --   action = wezterm.action.CopyMode 'MoveToEndOfLineContent',
--   -- },
--   -- {
--   --   key = ";",
--   --   mods = "CTRL",
--   --   action = wezterm.action_callback(function(window, pane)
--   --     local tab = window:active_tab()

--   --     -- Open pane below if current pane is vim
--   --     if is_vim(pane) then
--   --       if (#tab:panes()) == 1 then
--   --         -- Open pane below if when there is only one pane and it is vim
--   --         pane:split({ direction = "Bottom" })
--   --       else
--   --         -- Send `CTRL-; to vim`, navigate to bottom pane from vim
--   --         window:perform_action({
--   --           SendKey = { key = ";", mods = "CTRL" },
--   --         }, pane)
--   --       end
--   --       return
--   --     end

--   --     -- Zoom to vim pane if it exists
--   --     local vim_pane = find_vim_pane(tab)
--   --     if vim_pane then
--   --       vim_pane:activate()
--   --       tab:set_zoomed(true)
--   --     end
--   --   end),
--   -- },
-- }

-- -- config.key_tables = {
-- --   resize_panes = {
-- --     resize_pane('j', 'Down'),
-- --     resize_pane('k', 'Up'),
-- --     resize_pane('h', 'Left'),
-- --     resize_pane('l', 'Right'),
-- --   },

-- return config
