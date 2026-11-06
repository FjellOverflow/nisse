{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    recursive
  ];

  fonts.fontconfig.localConf = ''
    <alias>
      <family>Recursive Mono Linear Static</family>
      <accept>
        <family>Symbols Nerd Font Mono</family>
        <family>Adwaita Mono</family>
      </accept>
    </alias>
  '';
}
