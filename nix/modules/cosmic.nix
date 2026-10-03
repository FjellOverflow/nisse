{ pkgs, user, ... }:

{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  environment.cosmic.excludePackages = with pkgs; [
    cosmic-initial-setup
  ];

  home-manager.users.${user} =
    { cosmicLib, ... }:
    let
      inherit (cosmicLib.cosmic) importRON mkRON;
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
    };
}
