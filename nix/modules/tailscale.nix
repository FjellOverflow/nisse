_:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # keeps MagicDNS from breaking on resume: https://github.com/tailscale/tailscale/issues/4254
  services.resolved.enable = true;
}
