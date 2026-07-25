-- Keep only your personal looknfeel overrides here.
-- Currently commented out to use Omarchy's defaults.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 4,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },

    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },
  
  decoration = {
    rounding = 5,

    shadow = {
      enabled = false,
    },

    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
    }
  },
})