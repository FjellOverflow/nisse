{ pkgs, user, ... }:

{
  imports = [
    ../modules/brave.nix
    ../modules/gnupg.nix
    ../modules/mullvad.nix
    ../modules/syncthing.nix
  ];

  networking.networkmanager.enable = true;
  users.users.${user}.extraGroups = [ "networkmanager" ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libgbm
      libx11
      libxcb
      libxkbcommon
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      nss
      nspr
      pango
    ];
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  documentation.nixos.enable = false;

  system.activationScripts.avatar = ''
    install -D -m 0644 ${../assets/avatar.png} /var/lib/AccountsService/icons/${user}
  '';
  systemd.tmpfiles.rules = [
    "f /var/lib/AccountsService/users/${user} 0644 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${user}"
  ];

  home-manager.users.${user} = _: {
    home.file.".face".source = ../assets/avatar.png;
  };

  environment.systemPackages = with pkgs; [
    gparted
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.bitwarden.desktop"
    "com.spotify.Client"
    "md.obsidian.Obsidian"
    "org.freefilesync.FreeFileSync"
    "org.gimp.GIMP"
    "org.inkscape.Inkscape"
    "org.libreoffice.LibreOffice"
    "org.videolan.VLC"
  ];
}
