{ user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "vm";

  services.spice-webdavd.enable = true;

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";
}
