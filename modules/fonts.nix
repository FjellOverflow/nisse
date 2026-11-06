{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    recursive
  ];
}
