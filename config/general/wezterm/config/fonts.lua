local wezterm = require('wezterm')
local platform = require('utils.platform')
local fonts = require('utils.fonts')

return {
  font = wezterm.font({
    family = fonts.global.family,
    weight = fonts.global.weight,
  }),
  font_size = fonts.global.size,

  --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
  freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
