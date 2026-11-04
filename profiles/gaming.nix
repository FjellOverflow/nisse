{ pkgs, ... }:

{
  programs.steam.enable = true;

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    lutris
    mangohud
    protontricks
  ];
}
