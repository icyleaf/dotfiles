local platform = require('utils.platform')

local options = {
  default_prog = {},
  launch_menu = {},
}

if platform.is_win then
  options.default_prog = { 'pwsh', '-NoLogo' }
  options.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh', '-NoLogo' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { 'nu' } },
    {
        label = 'Git Bash',
        args = { 'C:\\Users\\icyleaf\\scoop\\apps\\git\\current\\bin\\bash.exe' },
    },
  }
elseif platform.is_mac then
  if platform.is_armed then
    options.default_prog = { '/opt/homebrew/bin/zsh', '-l' }
    options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
      { label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
    }
  else
    options.default_prog = { '/usr/local/bin/zsh', '-l' }
    options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { '/usr/local/bin/fish', '-l' } },
      { label = 'Nushell', args = { '/usr/local/bin/nu', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
    }
  end
elseif platform.is_linux then
  options.default_prog = { 'zsh', '-l' }
  options.launch_menu = {
    { label = 'Bash', args = { 'bash', '-l' } },
    { label = 'Fish', args = { 'fish', '-l' } },
    { label = 'Zsh', args = { 'zsh', '-l' } },
  }
end

return options
