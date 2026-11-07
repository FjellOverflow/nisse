<h1 align="center">nordfra</h1>

<p align="center">
  A personal take on Nord for the GNOME desktop
</p>

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nisse/theme.yaml?branch=main&label=CI"/>
  &ensp;
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/nisse?filter=theme-v*&label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/nisse?label=License"/>
</p>

> *Nordfra* (Norwegian: [ˈnuːrfrɑː]) means "from the north".

The theme lives in the [nisse](https://github.com/FjellOverflow/nisse) repository under `theme/`; its releases are tagged `theme-vX.Y.Z`.

Themes GNOME Shell, GTK 4 / libadwaita and GTK 3 apps, plus app, folder and file icons, in dark and light mode.

## Requirements

- GNOME Shell 51
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)
- The User Themes extension

## Install

Replace `X.Y.Z` with the latest `theme-v*` [release](https://github.com/FjellOverflow/nisse/releases).

```sh
curl -fLO https://github.com/FjellOverflow/nisse/releases/download/theme-vX.Y.Z/nordfra.tar.gz
tar -xzf nordfra.tar.gz
./nordfra/install.sh --dark   # or --light
```

Then select the theme and restart open apps:

```sh
gsettings set org.gnome.desktop.interface accent-color slate
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.desktop.interface icon-theme nordfra
```

Or in the GUI:

1. **Settings → Appearance**: choose the *Slate* accent.
2. **Extensions**: turn on *User Themes*.
3. **Tweaks → Appearance**: set *Icons* to `nordfra`.

For Flatpak apps (or in [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal): *All Applications → Filesystem*, add `xdg-config/gtk-3.0:ro` and `xdg-config/gtk-4.0:ro`):

```sh
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark org.gtk.Gtk3theme.adw-gtk3
```

### Light and dark mode

`--dark` and `--light` switch the colour scheme, *Legacy Applications* (`adw-gtk3-dark` / `adw-gtk3`) and the Shell theme (`nordfra` / `nordfra-light`). Rerun with the other option to switch. GTK 4 apps follow the quick-settings toggle; GTK 3 and the Shell don't, and the light Shell needs the `prefer-light` scheme that `--light` sets (the toggle sets `default`, which GNOME Shell treats as dark). As in stock GNOME, the top bar, overview, on-screen popups, lock and login screens stay dark in light mode. Without an option, the installer keeps the current mode.

The installer replaces `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` and backs up the originals as `*.nordfra-backup`.

### Icons

Apps without a nordfra icon fall back to Adwaita.

### Blur my Shell

Its styling overrides nordfra, so turn it off. On GNOME 51 its blur can't round corners, so also turn off the popup blur (square dark corners behind menus) and the panel blur (a dark line under the opaque top bar):

```sh
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/style-components 0
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolder/style-dialogs 0
dconf write /org/gnome/shell/extensions/blur-my-shell/popup/blur false
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/blur false
```

### Login screen

```sh
./nordfra/install-gdm.sh     # needs sudo; rerun after GNOME Shell updates
./nordfra/install-gdm.sh -r  # restore the stock login screen
./nordfra/gdm-resource.sh <stock.gresource> <out.gresource>  # only build it, e.g. for packaging
```

The login screen runs as the `gdm` user, so it ignores your font. To use your own, install it system-wide and set it for GDM:

```sh
printf "[org/gnome/desktop/interface]\nfont-name='Your Font 11'\n" | sudo tee /etc/dconf/db/gdm.d/01-font
sudo dconf update
```

## Uninstall

```sh
./nordfra/install.sh -r
```

This restores the backed-up files.

## Development

```sh
./build.sh      # renders the theme into dist/nordfra (needs jq and python3)
mise run theme:release  # from the nisse root: builds, updates CHANGELOG.md, commits and tags the next version; pushing the tag publishes it
```

Colours live in [`tokens.json`](tokens.json); templates in [`templates/`](templates/) reference them as `{{ group.key }}`. `colors_light` overrides `colors` in the light variant, and `build.sh` adds `{{ variant }}` (`dark` or `light`). The parts of the Shell that stay dark live in [`templates/shell/always-dark.css`](templates/shell/always-dark.css), which, like the icons, always gets the dark palette; it loads after [`themed.css`](templates/shell/themed.css) so its overrides win.

Icon glyphs in [`icons/`](icons/) fill the `{{ glyph }}` slot of [`templates/icons/`](templates/icons/). To add one, import it under the app's `Icon=` name (`--silhouette` for a full-colour source):

```sh
scripts/import-glyph.py /usr/share/icons/hicolor/symbolic/apps/org.gnome.Maps-symbolic.svg icons/apps/org.gnome.Maps.svg
```

File icons in [`icons/mimetypes/`](icons/mimetypes/) are Adwaita's, unmodified; `build.sh` recolours them from `tokens.json` with `scripts/recolour-mimetypes.py`. To add one, copy it from Adwaita under the same name.

The Shell theme targets one GNOME Shell version, pinned as `shell_version` in `scripts/check-shell-selectors.sh`. CI fails if a selector no longer exists in that version.
