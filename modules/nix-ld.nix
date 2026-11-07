{ pkgs, ... }:

{
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
}
