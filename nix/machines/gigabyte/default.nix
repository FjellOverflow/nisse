{ user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gigabyte";

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";
}
