{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-4e7a951c-dac2-4b12-bc9b-7401ca518802".device =
    "/dev/disk/by-uuid/4e7a951c-dac2-4b12-bc9b-7401ca518802";

  networking.hostName = "thinkpad";

  hardware.bluetooth.enable = true;
  services.thermald.enable = true;

  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";
}
