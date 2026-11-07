{ pkgs, user, ... }:

{
  environment.systemPackages = with pkgs; [ nil ];

  home-manager.users.${user} = _: {
    programs.vscodium = {
      enable = true;
      package = pkgs.vscodium.fhs;
      profiles.default.extensions = with pkgs.open-vsx; [
        jnoortheen.nix-ide
        vscode-icons-team.vscode-icons
        arcticicestudio.nord-visual-studio-code
        jeanp413.open-remote-ssh
      ];
      profiles.default.userSettings = {
        "editor.fontFamily" = "'Recursive Mono Linear Static', 'Symbols Nerd Font Mono'";
        "editor.fontSize" = 17.8;
        "editor.fontLigatures" = "'dlig'";
        "editor.wordWrap" = "on";
        "telemetry.telemetryLevel" = "off";
        "workbench.enableExperiments" = false;
        "chat.disableAIFeatures" = true;
        "workbench.startupEditor" = "none";
        "workbench.colorTheme" = "Nord";
        "workbench.iconTheme" = "vscode-icons";
        "vsicons.dontShowNewVersionMessage" = true;
        "window.dialogStyle" = "custom";
        "window.zoomLevel" = 1;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.formatOnSave" = true;
        };
      };
    };
  };
}
