local platform = require('utils.platform')

local font_family = 'Cascadia Mono'
local font_size = platform.is_mac and 14 or 12

return {
  global = {
    family = font_family,
    weight = 'Medium',
    size = font_size
  },
  window_frame = {
    family = font_family,
    weight = 'Bold',
    size = font_size
  },
  fallback = {
    'JetBrainsMono Nerd Font',
    'Source Code Pro',
    '霞鹜文楷等宽',
    'Maple Mono SC NF',
    'JetBrains Mono'
  }
}
