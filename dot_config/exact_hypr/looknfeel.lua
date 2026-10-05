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

  xwayland = {
    enabled = true,
    force_zero_scaling = true
  },

  -- Do not steal focus (and warp the cursor across monitors) when a window
  -- requests activation, e.g. an incoming IM message or a newly opened app.
  -- Overrides Omarchy's default focus_on_activate = true.
  misc = {
    focus_on_activate = false,
  }
})