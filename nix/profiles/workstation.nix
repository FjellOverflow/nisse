{
  pkgs,
  user,
  ...
}:

{
  imports = [
    ../modules/brave.nix
    ../modules/fonts.nix
    ../modules/gnome.nix
    ../modules/gnupg.nix
    ../modules/keyboard.nix
    ../modules/mise.nix
    ../modules/mullvad.nix
    ../modules/syncthing.nix
    ../modules/terminal.nix
    ../modules/vscodium.nix
  ];

  networking.networkmanager.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    gparted
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.bitwarden.desktop"
    "com.mattjakeman.ExtensionManager"
    "com.spotify.Client"
    "com.usebruno.Bruno"
    "md.obsidian.Obsidian"
    "org.freefilesync.FreeFileSync"
    "org.gimp.GIMP"
    "org.inkscape.Inkscape"
    "org.libreoffice.LibreOffice"
    "org.videolan.VLC"
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  users.users.${user} = {
    extraGroups = [ "libvirtd" ];
  };
}
