{ nixpkgs-2511, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "brick";

  hardware.bluetooth.enable = true;
  services.thermald.enable = true;

  # TODO: 26.05 introduced render issue
  hardware.graphics.package = nixpkgs-2511.legacyPackages.x86_64-linux.mesa;
}
