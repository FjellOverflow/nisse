{
  lib,
  pkgs,
  variables,
  user,
  ...
}:

{
  imports = [
    ../modules/tailscale.nix
  ];

  time.timeZone = variables.timeZone;
  i18n.defaultLocale = variables.defaultLocale;
  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_TIME"
    "LC_NUMERIC"
    "LC_MONETARY"
    "LC_PAPER"
    "LC_MEASUREMENT"
  ] (_: variables.regionalLocale);

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.${user} = {
    isNormalUser = true;
    description = variables.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    bat
    curl
    git
    gnupg
    nano
    ncdu
    tmux
    tree
    wget
  ];

  programs.fish.enable = true;

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libgbm
      libx11
      libxcb
      libxkbcommon
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      nss
      nspr
      pango
    ];
  };

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  home-manager.users.${user} = _: {
    programs.fish = {
      enable = true;
      shellAliases = {
        cat = "bat";
      };
      interactiveShellInit = ''
        set fish_greeting
        fish_add_path $HOME/.local/bin
        if type -q mise
          mise activate fish | source
        end
      '';
    };

    programs.starship.enable = true;

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = variables.fullName;
          inherit (variables) email signingKey;
        };
        commit = {
          gpgSign = true;
        };
        init.defaultBranch = "main";
      };
    };
  };
}
