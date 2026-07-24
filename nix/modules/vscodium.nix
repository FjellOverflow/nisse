{ pkgs, user, ... }:

{
  environment.systemPackages = with pkgs; [ nil ];

  home-manager.users.${user} =
    { pkgs, ... }:
    {
      programs.vscodium = {
        enable = true;
        package = pkgs.vscodium.fhs;
        profiles.default.extensions = with pkgs.open-vsx; [
          jnoortheen.nix-ide
          vscode-icons-team.vscode-icons
          zhuangtongfa.material-theme
          jeanp413.open-remote-ssh
        ];
        profiles.default.userSettings = {
          "editor.fontFamily" = "'FiraCode Nerd Font Mono'";
          "editor.fontLigatures" = true;
          "editor.wordWrap" = "on";
          "telemetry.telemetryLevel" = "off";
          "workbench.enableExperiments" = false;
          "chat.disableAIFeatures" = true;
          "workbench.startupEditor" = "none";
          "workbench.colorTheme" = "One Dark Pro";
          "workbench.iconTheme" = "vscode-icons";
          "vsicons.dontShowNewVersionMessage" = true;
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";
          "nix.formatterPath" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
          "editor.formatOnSave" = true;
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
        };
      };
    };
}
