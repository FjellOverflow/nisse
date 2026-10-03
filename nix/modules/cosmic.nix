{
  lib,
  pkgs,
  user,
  ...
}:

{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  environment.cosmic.excludePackages = with pkgs; [
    cosmic-initial-setup
  ];

  home-manager.users.${user} =
    { cosmicLib, osConfig, ... }:
    let
      inherit (cosmicLib.cosmic) importRON mkRON;
      appGroup = name: apps: {
        inherit name;
        icon = "folder-symbolic";
        filter = mkRON "enum" {
          variant = "AppIds";
          value = [ apps ];
        };
      };
    in
    {
      gtk.enable = true;
      gtk.theme = {
        name = "Nordic";
        package = pkgs.nordic;
      };

      wayland.desktopManager.cosmic = {
        enable = true;

        appearance.theme.mode = "dark";
        # palette is stock cosmic-dark, corner_radii are dropped for COSMIC's round default
        appearance.theme.dark = removeAttrs (importRON ../assets/themes/nord-dark.ron) [
          "palette"
          "corner_radii"
        ];
        appearance.toolkit.apply_theme_global = true;

        applets.time.settings = {
          military_time = true;
          show_weekday = true;
          first_day_of_week = 0;
        };

        applets.app-list.settings.favorites = [
          "com.system76.CosmicTerm"
          "brave-browser"
          "codium"
          "com.system76.CosmicFiles"
          "md.obsidian.Obsidian"
          "com.bitwarden.desktop"
          "com.spotify.Client"
          "org.gnome.Boxes"
          "mullvad-vpn"
          "bruno"
        ];

        shortcuts = [
          {
            description = mkRON "optional" "Launch terminal";
            key = "Super+Return";
            action = mkRON "enum" {
              variant = "System";
              value = [ (mkRON "enum" "Terminal") ];
            };
          }
        ];

        configFile."com.system76.CosmicTerm" = {
          version = 1;
          entries = {
            font_name = "FiraCode Nerd Font Mono";
            font_size = 16;
          };
        };
      };

      programs.cosmic-applibrary = {
        enable = true;
        package = null;
        settings.groups = [
          (appGroup "Disk" [ "gparted" ])
          (appGroup "Graphics" [
            "org.gimp.GIMP"
            "org.inkscape.Inkscape"
          ])
          (appGroup "Media" [
            "com.system76.CosmicPlayer"
            "org.videolan.VLC"
          ])
          (appGroup "Office" [
            "org.libreoffice.LibreOffice"
            "org.libreoffice.LibreOffice.base"
            "org.libreoffice.LibreOffice.calc"
            "org.libreoffice.LibreOffice.draw"
            "org.libreoffice.LibreOffice.impress"
            "org.libreoffice.LibreOffice.math"
            "org.libreoffice.LibreOffice.writer"
          ])
          (appGroup "Settings" [ "com.system76.CosmicSettings" ])
          (appGroup "Sync" [
            "org.freefilesync.FreeFileSync"
            "org.freefilesync.FreeFileSync.RealTimeSync"
            "syncthing-ui"
          ])
          (appGroup "Utilities" [
            "com.system76.CosmicEdit"
            "com.system76.CosmicReader"
            "com.system76.CosmicScreenshot"
          ])
        ]
        ++ lib.optional osConfig.programs.steam.enable (
          appGroup "Gaming" [
            "steam"
            "net.lutris.Lutris"
            "protontricks"
          ]
        );
      };
    };
}
