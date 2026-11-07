{
  pkgs,
  nordfra,
  user,
  ...
}:

let
  tokens = builtins.fromJSON (builtins.readFile ../theme/tokens.json);
  uiFont = "Recursive Sans Linear Static 11";
in
{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    gnomeExtensions.blur-my-shell
  ];

  # GDM's theme lives in gnome-shell's own gresource, so it needs patching here.
  nixpkgs.overlays = [
    (_: prev: {
      gnome-shell = prev.gnome-shell.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          PATH=${prev.glib.dev}/bin:$PATH sh ${nordfra}/gdm-resource.sh \
            $out/share/gnome-shell/gnome-shell-theme.gresource \
            $out/share/gnome-shell/gnome-shell-theme.gresource
        '';
      });
    })
  ];

  programs.dconf.profiles.gdm.databases = [
    { settings."org/gnome/desktop/interface".font-name = uiFont; }
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [ "org.gtk.Gtk3theme.adw-gtk3-dark" ];
  services.flatpak.overrides.global.Context.filesystems = [
    "xdg-config/gtk-3.0:ro"
    "xdg-config/gtk-4.0:ro"
    "/nix/store:ro"
  ];

  home-manager.users.${user} = _: {
    xdg.configFile."gtk-3.0/gtk.css".source = "${nordfra}/variants/dark/config/gtk-3.0/gtk.css";
    xdg.configFile."gtk-4.0/gtk.css".source = "${nordfra}/config/gtk-4.0/gtk.css";
    xdg.dataFile."themes/nordfra".source = "${nordfra}/data/themes/nordfra";
    xdg.dataFile."icons/nordfra".source = "${nordfra}/data/icons/nordfra";

    # merged with the list in gnome.nix
    dconf.settings."org/gnome/shell".enabled-extensions = [
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "blur-my-shell@aunetx"
    ];

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "nordfra";
      accent-color = tokens.gnome_accent;
      font-name = uiFont;
      document-font-name = "Recursive Sans Linear Static 12";
      monospace-font-name = "Recursive Mono Linear Static 11";
    };

    dconf.settings."org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Recursive Sans Linear Static SemiBold 11";
    };

    dconf.settings."org/gnome/shell/extensions/user-theme" = {
      name = "nordfra";
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/overview" = {
      style-components = 0;
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      style-dialogs = 0;
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/popup" = {
      blur = false;
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = false;
    };
  };
}
