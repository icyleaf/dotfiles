local wezterm = require("wezterm")
local domain = {}

function domain.create_ssh_domain_from_ssh_config()
  ssh_domains = {}
  for host, config in pairs(wezterm.enumerate_ssh_hosts()) do
    table.insert(ssh_domains, {
      name = host,
      remote_address = config.hostname .. ":" .. config.port,
      username = config.user,
      multiplexing = "None",
      assume_shell = "Posix",
    })
  end
  return ssh_domains
end

return domain
