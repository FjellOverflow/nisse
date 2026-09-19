{
  imports = [
    ../modules/gnome.nix
    ../modules/ptyxis.nix
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.mattjakeman.ExtensionManager"
  ];
}
