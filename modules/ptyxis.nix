{ pkgs, user, ... }:

{
  environment.systemPackages = with pkgs; [ ptyxis ];

  home-manager.users.${user} = _: {
    dconf.settings."org/gnome/Ptyxis" = {
      audible-bell = false;
      visual-bell = false;
      use-system-font = false;
      font-name = "FiraCode Nerd Font Mono 16";
      default-profile-uuid = "00000000-0000-0000-0000-000000000001";
      profile-uuids = [ "00000000-0000-0000-0000-000000000001" ];
    };

    dconf.settings."org/gnome/Ptyxis/Profiles/00000000-0000-0000-0000-000000000001" = {
      palette = "nord";
    };
  };
}
