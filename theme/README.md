<h1 align="center">nordix theme</h1>

<p align="center">
  Opinionated Nord theme for GNOME
</p>

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nordix/theme.yaml?branch=main&label=CI"/>
  &ensp;
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/nordix?filter=theme-v*&label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/nordix?label=License"/>
</p>

GNOME Shell, GTK 4 / libadwaita, GTK 3, icons and the login screen, in dark and light.

Part of [nordix](../README.md). Without NixOS, install a [release](https://github.com/FjellOverflow/nordix/releases) as below.

## Requirements

- GNOME Shell 51
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)
- User Themes extension

## Install

```sh
curl -fLO https://github.com/FjellOverflow/nordix/releases/download/theme-vX.Y.Z/nordix-theme.tar.gz
tar -xzf nordix-theme.tar.gz
./nordix-theme/install.sh --dark   # or --light
```

Then select it and restart open apps:

```sh
gsettings set org.gnome.desktop.interface accent-color slate
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.desktop.interface icon-theme nordix-icons
```

Flatpak apps:

```sh
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
```

The installer replaces `~/.config/gtk-{3,4}.0/gtk.css`; originals are kept as `*.nordix-backup`.

### Light and dark mode

Switch by rerunning `install.sh` with the other option; without one it keeps the current mode. The quick-settings toggle only switches GTK 4 apps, and sets `default`, which the Shell treats as dark. The top bar, overview, popups, lock and login screens stay dark, as in stock GNOME.

### Blur my Shell

Turn off its styling, the overview blur, and the popup and panel blur (it can't round corners on GNOME 51):

```sh
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/blur false
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/style-components 0
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolder/style-dialogs 0
dconf write /org/gnome/shell/extensions/blur-my-shell/popup/blur false
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/blur false
```

### Login screen

```sh
./nordix-theme/install-gdm.sh     # needs sudo; rerun after GNOME Shell updates
./nordix-theme/install-gdm.sh -r  # restore stock
./nordix-theme/gdm-resource.sh <stock.gresource> <out.gresource>  # build only, for packaging
```

GDM ignores your font. To set one, install it system-wide and:

```sh
printf "[org/gnome/desktop/interface]\nfont-name='Your Font 11'\n" | sudo tee /etc/dconf/db/gdm.d/01-font
sudo dconf update
```

## Uninstall

```sh
./nordix-theme/install.sh -r   # restores the backups
```

## Development

```sh
./build.sh              # render into dist/nordix-theme
mise run theme:release  # from the repo root: changelog, commit, signed tag; pushing the tag publishes
```

- Colours: [`tokens.json`](tokens.json), referenced in [`templates/`](templates/) as `{{ group.key }}`. `colors_light` overrides `colors`; `{{ variant }}` is `dark` or `light`.
- Always-dark Shell parts: [`always-dark.css`](templates/shell/always-dark.css), always rendered with the dark palette and loaded after [`themed.css`](templates/shell/themed.css).
- App and folder glyphs: [`icons/`](icons/), filling `{{ glyph }}` in [`templates/icons/`](templates/icons/). Import under the app's `Icon=` name (`--silhouette` for full-colour sources):

  ```sh
  scripts/import-glyph.py /usr/share/icons/hicolor/symbolic/apps/org.gnome.Maps-symbolic.svg icons/apps/org.gnome.Maps.svg
  ```

- File icons: [`icons/mimetypes/`](icons/mimetypes/), unmodified Adwaita copies, recoloured at build time.
- Shell version: pinned as `shell_version` in `scripts/check-shell-selectors.sh`; CI fails on selectors missing there.
