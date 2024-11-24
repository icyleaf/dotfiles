local wezterm = require('wezterm')
local gpu_adapters = require('utils.gpu_adapter')

-- A slightly altered version of catppucchin mocha
local mocha = {
  rosewater = '#f5e0dc',
  flamingo = '#f2cdcd',
  pink = '#f5c2e7',
  mauve = '#cba6f7',
  red = '#f38ba8',
  maroon = '#eba0ac',
  peach = '#fab387',
  yellow = '#f9e2af',
  green = '#a6e3a1',
  teal = '#94e2d5',
  sky = '#89dceb',
  sapphire = '#74c7ec',
  blue = '#89b4fa',
  lavender = '#b4befe',
  text = '#cdd6f4',
  subtext1 = '#bac2de',
  subtext0 = '#a6adc8',
  overlay2 = '#9399b2',
  overlay1 = '#7f849c',
  overlay0 = '#6c7086',
  surface2 = '#585b70',
  surface1 = '#45475a',
  surface0 = '#313244',
  base = '#1f1f28',
  mantle = '#181825',
  crust = '#11111b',
}

local colors = {
  foreground = mocha.text,
  background = mocha.base,
  cursor_bg = mocha.rosewater,
  cursor_border = mocha.rosewater,
  cursor_fg = mocha.crust,
  selection_bg = mocha.surface2,
  selection_fg = mocha.text,
  ansi = {
    '#0C0C0C', -- black
    '#C50F1F', -- red
    '#13A10E', -- green
    '#C19C00', -- yellow
    '#0037DA', -- blue
    '#881798', -- magenta/purple
    '#3A96DD', -- cyan
    '#CCCCCC', -- white
  },
  brights = {
    '#767676', -- black
    '#E74856', -- red
    '#16C60C', -- green
    '#F9F1A5', -- yellow
    '#3B78FF', -- blue
    '#B4009E', -- magenta/purple
    '#61D6D6', -- cyan
    '#F2F2F2', -- white
  },
  tab_bar = {
    background = 'rgba(0, 0, 0, 0.4)',
    active_tab = {
      bg_color = mocha.surface2,
      fg_color = mocha.text,
    },
    inactive_tab = {
      bg_color = mocha.surface0,
      fg_color = mocha.subtext1,
    },
    inactive_tab_hover = {
      bg_color = mocha.surface0,
      fg_color = mocha.text,
    },
    new_tab = {
      bg_color = mocha.base,
      fg_color = mocha.text,
    },
    new_tab_hover = {
      bg_color = mocha.mantle,
      fg_color = mocha.text,
      italic = true,
    },
  },
  visual_bell = mocha.surface0,
  indexed = {
    [16] = mocha.peach,
    [17] = mocha.rosewater,
  },
  scrollbar_thumb = mocha.surface2,
  split = mocha.overlay0,
  compose_cursor = mocha.flamingo,
}

local wayland_mode = false
if os.getenv("XDG_CURRENT_DESKTOP") == "Hyprland" then
  wayland_mode = true
end

return {
  enable_wayland = wayland_mode,
  animation_fps = 60,
  max_fps = 60,
  front_end = 'WebGpu',
  webgpu_power_preference = 'HighPerformance',
  webgpu_preferred_adapter = gpu_adapters:pick_best(),

  -- color scheme
  colors = colors,

  -- background
  -- background = {
  --   {
  --     source = { File = wezterm.GLOBAL.background },
  --     horizontal_align = 'Center',
  --   },
  --   {
  --     source = { Color = colors.background },
  --     height = '120%',
  --     width = '120%',
  --     vertical_offset = '-10%',
  --     horizontal_offset = '-10%',
  --     opacity = 0.96,
  --   },
  -- },

  -- scrollbar
  enable_scroll_bar = true,

  -- tab bar
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = false,
  tab_max_width = 25,
  show_tab_index_in_tab_bar = true,
  switch_to_last_active_tab_when_closing_tab = true,

  -- window
  -- window_padding = {
  --   left = 0,
  --   right = 0,
  --   top = 10,
  --   bottom = 7.5,
  -- },
  window_close_confirmation = 'NeverPrompt',
  window_frame = {
    active_titlebar_bg = '#090909',
    -- font = fonts.font,
    -- font_size = fonts.font_size,
  },
  inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.65,
  },
  inactive_pane_hsb = {
    saturation = 1,
    brightness = 1,
  },
}
