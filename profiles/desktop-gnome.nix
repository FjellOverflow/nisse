{
  imports = [
    ../modules/gnome.nix
    ../modules/ptyxis.nix
    ../modules/theme.nix
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.mattjakeman.ExtensionManager"
  ];
}
