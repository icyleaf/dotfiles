local wezterm = require('wezterm')
local gpu_adapters = require('utils.gpu_adapter')
local platform = require('utils.platform')
local fonts = require('utils.fonts')

return {
  enable_wayland = platform.is_wayland,
  animation_fps = 60,
  max_fps = 60,
  front_end = 'WebGpu',
  webgpu_power_preference = 'HighPerformance',
  webgpu_preferred_adapter = gpu_adapters:pick_best(),

  -- cursor
  animation_fps = 120,
  cursor_blink_ease_in = 'EaseOut',
  cursor_blink_ease_out = 'EaseOut',
  default_cursor_style = 'BlinkingBlock',
  cursor_blink_rate = 650,

  -- color scheme
  color_scheme = 'Seti',

  -- scrollbar
  enable_scroll_bar = true,

  -- tab bar
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = true,
  tab_max_width = 25,
  show_tab_index_in_tab_bar = true,
  switch_to_last_active_tab_when_closing_tab = true,
  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 1.0
  },

  -- window
  adjust_window_size_when_changing_font_size = false,
  window_decorations = "RESIZE",
  window_close_confirmation = 'NeverPrompt',
  window_background_opacity = 0.9,
  macos_window_background_blur = 10,
  native_macos_fullscreen_mode = false,
  window_frame = {
    active_titlebar_bg = '#090909',
    font = wezterm.font({
      family = fonts.window_frame.family,
      weight = fonts.window_frame.weight,
    }),
    font_size = fonts.window_frame.size,
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
