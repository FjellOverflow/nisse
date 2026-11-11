{
  pkgs,
  nordix-theme,
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
          PATH=${prev.glib.dev}/bin:$PATH sh ${nordix-theme}/gdm-resource.sh \
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
    xdg.configFile."gtk-3.0/gtk.css".source = "${nordix-theme}/variants/dark/config/gtk-3.0/gtk.css";
    xdg.configFile."gtk-4.0/gtk.css".source = "${nordix-theme}/config/gtk-4.0/gtk.css";
    xdg.dataFile."themes/nordix-dark".source = "${nordix-theme}/data/themes/nordix-dark";
    xdg.dataFile."icons/nordix-icons".source = "${nordix-theme}/data/icons/nordix-icons";

    # merged with the list in gnome.nix
    dconf.settings."org/gnome/shell".enabled-extensions = [
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "blur-my-shell@aunetx"
    ];

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "Adwaita";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "nordix-icons";
      accent-color = tokens.gnome_accent;
      font-name = uiFont;
      document-font-name = "Recursive Sans Linear Static 12";
      monospace-font-name = "Recursive Mono Linear Static 11";
    };

    dconf.settings."org/gnome/desktop/wm/preferences" = {
      titlebar-font = "Recursive Sans Linear Static SemiBold 11";
    };

    dconf.settings."org/gnome/shell/extensions/user-theme" = {
      name = "nordix-dark";
    };

    dconf.settings."org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = false;
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
