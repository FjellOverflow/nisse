{ pkgs, user, ... }:

{
  services.xserver.enable = true;
  services.xserver.excludePackages = with pkgs; [ xterm ];

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;

  environment.systemPackages = with pkgs; [
    baobab
    dconf-editor
    decibels
    deja-dup
    gnome-boxes
    gnome-shell-extensions
    gnome-calculator
    gnome-connections
    gnome-disk-utility
    gnome-font-viewer
    gnome-logs
    gnome-system-monitor
    gnome-text-editor
    gnome-tweaks
    loupe
    nautilus
    papers
    seahorse
    showtime
    snapshot
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/AccountsService/icons/${user} - - - - ${../assets/avatar.png}"
    "f /var/lib/AccountsService/users/${user} 0644 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${user}"
  ];

  home-manager.users.${user} = _: {
    home.file.".face".source = ../assets/avatar.png;

    dconf.settings."org/gnome/desktop/background" = {
      picture-uri = "file://${../assets/wallpapers/nixos.png}";
      picture-uri-dark = "file://${../assets/wallpapers/nixos.png}";
      picture-options = "zoom";
    };

    dconf.settings."org/gnome/desktop/interface" = {
      clock-format = "24h";
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
    };

    dconf.settings."org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };

    dconf.settings."org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    dconf.settings."org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
    };

    dconf.settings."org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    dconf.settings."org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "ptyxis --new-window";
      name = "Launch terminal";
    };

    dconf.settings."org/gnome/desktop/privacy" = {
      report-technical-problems = false;
    };

    dconf.settings."org/gnome/system/location" = {
      enabled = false;
    };

    dconf.settings."org/gnome/shell" = {
      enabled-extensions = [
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "window-list@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "gsconnect@andyholmes.github.io"
      ];
      favorite-apps = [
        "org.gnome.Ptyxis.desktop"
        "brave-browser.desktop"
        "codium.desktop"
        "org.gnome.Nautilus.desktop"
        "md.obsidian.Obsidian.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders" = {
      folder-children = [
        "Disk"
        "Graphics"
        "Media"
        "Office"
        "Settings"
        "Sync"
        "System"
        "Utilities"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Disk" = {
      name = "Disk";
      apps = [
        "org.gnome.baobab.desktop"
        "org.gnome.DiskUtility.desktop"
        "gparted.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Graphics" = {
      name = "Graphics";
      apps = [
        "org.gimp.GIMP.desktop"
        "org.inkscape.Inkscape.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Media" = {
      name = "Media";
      apps = [
        "org.gnome.Decibels.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.Showtime.desktop"
        "org.videolan.VLC.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Office" = {
      name = "Office";
      apps = [
        "org.libreoffice.LibreOffice.desktop"
        "org.libreoffice.LibreOffice.base.desktop"
        "org.libreoffice.LibreOffice.calc.desktop"
        "org.libreoffice.LibreOffice.draw.desktop"
        "org.libreoffice.LibreOffice.impress.desktop"
        "org.libreoffice.LibreOffice.math.desktop"
        "org.libreoffice.LibreOffice.writer.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Settings" = {
      name = "Settings";
      apps = [
        "ca.desrt.dconf-editor.desktop"
        "com.mattjakeman.ExtensionManager.desktop"
        "org.gnome.Extensions.desktop"
        "org.gnome.Settings.desktop"
        "org.gnome.tweaks.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Sync" = {
      name = "Sync";
      apps = [
        "org.freefilesync.FreeFileSync.desktop"
        "org.freefilesync.FreeFileSync.RealTimeSync.desktop"
        "syncthing-ui.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/System" = {
      name = "System";
      apps = [
        "org.gnome.Connections.desktop"
        "org.gnome.font-viewer.desktop"
        "org.gnome.Logs.desktop"
        "org.gnome.SystemMonitor.desktop"
      ];
    };

    dconf.settings."org/gnome/desktop/app-folders/folders/Utilities" = {
      name = "Utilities";
      apps = [
        "org.gnome.Calculator.desktop"
        "org.gnome.Snapshot.desktop"
        "org.gnome.Papers.desktop"
        "org.gnome.TextEditor.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
    };
  };
}
