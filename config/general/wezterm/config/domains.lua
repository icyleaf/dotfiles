local domain = require('utils.domain')
local ssh_domains = domain.create_ssh_domain_from_ssh_config()

return {
  -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
  ssh_domains = ssh_domains,

  -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
  unix_domains = {},

  -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
  wsl_domains = {
    {
      name = 'WSL:Ubuntu',
      distribution = 'Ubuntu',
      username = 'icyleaf',
      default_cwd = '/home/icyleaf',
      default_prog = { 'zsh', '-l' },
    },
  },
}
