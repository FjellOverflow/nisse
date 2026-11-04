{ pkgs, user, ... }:

{
  services.syncthing = {
    enable = true;
    inherit user;
    dataDir = "/home/${user}/Syncthing";
    configDir = "/home/${user}/.config/syncthing";
  };
  environment.systemPackages = with pkgs; [ syncthing ];
}
