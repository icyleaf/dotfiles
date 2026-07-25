-- Personal input overrides

hl.config({
  input = {
    kb_layout = "us",
    kb_options = "compose:caps",

    repeat_rate = 40,
    repeat_delay = 600,

    numlock_by_default = true,

    sensitivity = 0,
    force_no_accel = 1,

    follow_mouse = 1,
    natural_scroll = true,
    scroll_factor = 1.0,

    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },
})

hl.config({
  gestures = {
    workspace_swipe_invert = true,
    workspace_swipe_min_speed_to_force = 30,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = false,
  }
})