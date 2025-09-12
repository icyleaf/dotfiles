local wezterm = require("wezterm")
local domain = {}

-- Create SSH domains from SSH config
-- https://github.com/yutkat/dotfiles/blob/main/.config/wezterm/wezterm.lua#L28
function domain.create_ssh_domain_from_ssh_config()
  ssh_domains = {}
  for host, config in pairs(wezterm.enumerate_ssh_hosts()) do
    table.insert(ssh_domains, {
      name = host,
      remote_address = config.hostname .. ":" .. config.port,
      username = config.user,
      connect_automatically = false,
      multiplexing = "WezTerm",
      assume_shell = "Posix",
    })
  end
  return ssh_domains
end

return domain
