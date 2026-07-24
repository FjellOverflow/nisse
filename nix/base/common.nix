{ pkgs, user, ... }:

{
  imports = [
    ../modules/tailscale.nix
    ../modules/docker.nix
  ];

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
  };

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

  system.stateVersion = "25.11";
  security.sudo.wheelNeedsPassword = false;

  users.users.${user} = {
    isNormalUser = true;
    description = "FjellOverflow";
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
    home.stateVersion = "25.11";

    programs.fish = {
      enable = true;
      shellAliases = {
        cat = "bat";
      };
      interactiveShellInit = ''
        set fish_greeting
        if type -q mise
          mise activate fish | source
        end
      '';
    };

    programs.starship.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "FjellOverflow";
          email = "fjelloverflow@protonmail.com";
          signingKey = "1F460E4716149438";
        };
        commit = {
          gpgSign = true;
        };
        init.defaultBranch = "main";
      };
    };
  };
}
