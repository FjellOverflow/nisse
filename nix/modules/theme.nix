{
  pkgs,
  nordfra,
  user,
  ...
}:

let
  tokens = builtins.fromJSON (builtins.readFile "${nordfra}/tokens.json");
in
{
  environment.systemPackages = with pkgs; [ adw-gtk3 ];

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

  services.flatpak.packages = [ "org.gtk.Gtk3theme.adw-gtk3-dark" ];
  services.flatpak.overrides.global.Context.filesystems = [
    "xdg-config/gtk-3.0:ro"
    "xdg-config/gtk-4.0:ro"
    "/nix/store:ro"
  ];

  home-manager.users.${user} = _: {
    xdg.configFile."gtk-3.0/gtk.css".source = "${nordfra}/config/gtk-3.0/gtk.css";
    xdg.configFile."gtk-4.0/gtk.css".source = "${nordfra}/config/gtk-4.0/gtk.css";
    xdg.dataFile."themes/nordfra".source = "${nordfra}/data/themes/nordfra";

    dconf.settings."org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      accent-color = tokens.gnome_accent;
    };

    dconf.settings."org/gnome/shell/extensions/user-theme" = {
      name = "nordfra";
    };
  };
}
