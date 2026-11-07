{ pkgs, user, ... }:

{
  imports = [
    ../modules/audio.nix
    ../modules/brave.nix
    ../modules/gnome.nix
    ../modules/mullvad.nix
    ../modules/ptyxis.nix
    ../modules/spotify.nix
    ../modules/syncthing.nix
    ../modules/theme.nix
  ];

  networking.networkmanager.enable = true;
  users.users.${user}.extraGroups = [ "networkmanager" ];

  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    gparted
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.bitwarden.desktop"
    "com.mattjakeman.ExtensionManager"
    "md.obsidian.Obsidian"
    "org.gimp.GIMP"
    "org.inkscape.Inkscape"
    "org.libreoffice.LibreOffice"
    "org.videolan.VLC"
  ];
}
