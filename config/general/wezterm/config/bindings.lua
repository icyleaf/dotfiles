local wezterm = require('wezterm')
local platform = require('utils.platform')
local tables = require('utils.table')
local act = wezterm.action

local mod = {}

if platform.is_mac then
  mod.SUPER = 'SUPER'
  mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
  mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
  mod.SUPER_REV = 'ALT|CTRL'
end

-- stylua: ignore
local keys = {
  -- misc/useful --
  { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
  { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
  { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
  { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
  {
    key = 'F5',
    mods = 'NONE',
    action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
  },
  { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
  { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
  { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
  {
    key = 'u',
    mods = mod.SUPER,
    action = wezterm.action.QuickSelectArgs({
      label = 'open url',
      patterns = {
        '\\((https?://\\S+)\\)',
        '\\[(https?://\\S+)\\]',
        '\\{(https?://\\S+)\\}',
        '<(https?://\\S+)>',
        '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
      },
      action = wezterm.action_callback(function(window, pane)
        local url = window:get_selection_text_for_pane(pane)
        wezterm.log_info('opening: ' .. url)
        wezterm.open_with(url)
      end),
    }),
  },

  -- tabs --
  -- tabs: spawn+close
  { key = 't',          mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },
  -- { key = 't',          mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
  { key = 'w',          mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },

  -- tabs: navigation
  { key = '[',          mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
  { key = ']',          mods = mod.SUPER,     action = act.ActivateTabRelative(1) },
  { key = '[',          mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
  { key = ']',          mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

  -- tab: title
  { key = '0',          mods = mod.SUPER,     action = act.EmitEvent('tabs.manual-update-tab-title') },
  { key = '0',          mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },

  -- tab: hide tab-bar
  { key = '9',          mods = mod.SUPER,     action = act.EmitEvent('tabs.toggle-tab-bar'), },

  -- window --
  -- spawn windows
  { key = 'n',          mods = mod.SUPER,     action = act.SpawnWindow },

  -- background controls --
  --  {
  --     key = [[/]],
  --     mods = mod.SUPER,
  --     action = wezterm.action_callback(function(window, _pane)
  --        backdrops:random(window)
  --     end),
  --  },
  --  {
  --     key = [[,]],
  --     mods = mod.SUPER,
  --     action = wezterm.action_callback(function(window, _pane)
  --        backdrops:cycle_back(window)
  --     end),
  --  },
  --  {
  --     key = [[.]],
  --     mods = mod.SUPER,
  --     action = wezterm.action_callback(function(window, _pane)
  --        backdrops:cycle_forward(window)
  --     end),
  --  },
  --  {
  --     key = [[/]],
  --     mods = mod.SUPER_REV,
  --     action = act.InputSelector({
  --        title = 'InputSelector: Select Background',
  --        choices = backdrops:choices(),
  --        fuzzy = true,
  --        fuzzy_description = 'Select Background: ',
  --        action = wezterm.action_callback(function(window, _pane, idx)
  --           if not idx then
  --              return
  --           end
  --           ---@diagnostic disable-next-line: param-type-mismatch
  --           backdrops:set_img(window, tonumber(idx))
  --        end),
  --     }),
  --  },
  --  {
  --     key = 'b',
  --     mods = mod.SUPER,
  --     action = wezterm.action_callback(function(window, _pane)
  --        backdrops:toggle_focus(window)
  --     end)
  --  },

  -- panes --
  -- panes: split panes
  {
    key = [[\]],
    mods = mod.SUPER,
    action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
  },
  {
    key = [[\]],
    mods = mod.SUPER_REV,
    action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  },

  -- panes: zoom+close pane
  { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
  { key = 'w',     mods = mod.SUPER,     action = act.CloseCurrentPane({ confirm = false }) },

  -- panes: navigation
  { key = 'k',     mods = mod.SUPER, action = act.ActivatePaneDirection('Up') },
  { key = 'j',     mods = mod.SUPER, action = act.ActivatePaneDirection('Down') },
  { key = 'h',     mods = mod.SUPER, action = act.ActivatePaneDirection('Left') },
  { key = 'l',     mods = mod.SUPER, action = act.ActivatePaneDirection('Right') },
  {
    key = 'p',
    mods = mod.SUPER_REV,
    action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
  },
  -- key-tables --
  -- resizes fonts
  {
    key = 'f',
    mods = 'LEADER',
    action = act.ActivateKeyTable({
      name = 'resize_font',
      one_shot = false,
      timemout_miliseconds = 1000,
    }),
  },
  -- resize panes
  {
    key = 'p',
    mods = 'LEADER',
    action = act.ActivateKeyTable({
      name = 'resize_pane',
      one_shot = false,
      timemout_miliseconds = 1000,
    }),
  },
}

local macos_keys = {
  -- copy/paste --
  { key = 'c',          mods = mod.SUPER,  action = act.CopyTo('Clipboard') },
  { key = 'v',          mods = mod.SUPER,  action = act.PasteFrom('Clipboard') },

  -- quite application
  { key = 'q',          mods = mod.SUPER,  action = act.QuitApplication }
}

local linux_keys = {
  -- copy/paste --
  { key = 'c',          mods = 'CTRL|SHIFT',  action = act.CopyTo('Clipboard') },
  { key = 'v',          mods = 'CTRL|SHIFT',  action = act.PasteFrom('Clipboard') },

  -- cursor movement --
  { key = 'LeftArrow',  mods = mod.SUPER,     action = act.SendString '\x1bOH' },
  { key = 'RightArrow', mods = mod.SUPER,     action = act.SendString '\x1bOF' },
  { key = 'Backspace',  mods = mod.SUPER,     action = act.SendString '\x15' },
  -- { key = 'LeftArrow',  mods = mod.SUPER,     action = wezterm.action.SendKey({ mods = "CTRL", key = "a" }) },
  -- { key = 'RightArrow', mods = mod.SUPER,     action = wezterm.action.SendKey({ mods = "CTRL", key = "e" }) },
  -- { key = 'Backspace',  mods = mod.SUPER,     action = wezterm.action.SendKey({ mods = "CTRL", key = "u" }) },
  -- { key = 'LeftArrow',  mods = mod.SUPER_REV, action = wezterm.action.SendKey({ mods = "ALT", key = "b" }) },
  -- { key = 'RightArrow', mods = mod.SUPER_REV, action = wezterm.action.SendKey({ mods = "ALT", key = "f" }) },
}

-- stylua: ignore
local key_tables = {
  resize_font = {
    { key = 'k',      action = act.IncreaseFontSize },
    { key = '=',      action = act.IncreaseFontSize },
    { key = 'j',      action = act.DecreaseFontSize },
    { key = '-',      action = act.DecreaseFontSize },
    { key = 'r',      action = act.ResetFontSize },
    { key = '0',      action = act.ResetFontSize },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'q',      action = 'PopKeyTable' },
  },
  resize_pane = {
    { key = 'k',      action = act.AdjustPaneSize({ 'Up', 1 }) },
    { key = 'j',      action = act.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'h',      action = act.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'l',      action = act.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'q',      action = 'PopKeyTable' },
  },
}

local mouse_bindings = {
  -- Ctrl-click will open the link under the mouse cursor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
}

if platform.is_mac then
  tables.merge_config(keys, macos_keys)
else
  tables.merge_config(keys, linux_keys)
end

for i = 1, 8 do
  -- SUPER + number to activate that tab
  table.insert(keys, {
    key = tostring(i),
    mods = mod.SUPER,
    action = act.ActivateTab(i - 1),
  })
end

return {
  disable_default_key_bindings = true,
  leader = { key = 'a', mods = mod.SUPER_REV },
  keys = keys,
  key_tables = key_tables,
  mouse_bindings = mouse_bindings,
}