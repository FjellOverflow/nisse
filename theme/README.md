<h1 align="center">nordfra</h1>

<p align="center">
  A personal take on Nord for the GNOME desktop
</p>

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nordfra/ci.yaml?branch=main&label=CI"/>
  &ensp;
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/nordfra?label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/nordfra?label=License"/>
</p>

> *Nordfra* (Norwegian: [ˈnuːrfrɑː]) means "from the north".

Themes GNOME Shell, GTK 4 / libadwaita and GTK 3 apps, plus app, folder and file icons. Dark mode only.

## Requirements

- GNOME Shell 50
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)
- The User Themes extension

## Install

```sh
curl -fLO https://github.com/FjellOverflow/nordfra/releases/latest/download/nordfra.tar.gz
tar -xzf nordfra.tar.gz
./nordfra/install.sh
```

Then select the theme and restart open apps:

```sh
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface accent-color slate
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.shell.extensions.user-theme name nordfra
gsettings set org.gnome.desktop.interface icon-theme nordfra
```

Or in the GUI:

1. **Settings → Appearance**: choose *Dark* and the *Slate* accent.
2. **Extensions**: turn on *User Themes*.
3. **Tweaks → Appearance**: set *Legacy Applications* to `adw-gtk3-dark`, *Shell* and *Icons* to `nordfra`.

For Flatpak apps (or in [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal): *All Applications → Filesystem*, add `xdg-config/gtk-3.0:ro` and `xdg-config/gtk-4.0:ro`):

```sh
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark
```

The installer replaces `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` and backs up the originals as `*.nordfra-backup`.

### Icons

Apps without a nordfra icon fall back to Adwaita.

### Blur my Shell

Its styling overrides nordfra, so turn it off:

```sh
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/style-components 0
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolder/style-dialogs 0
```

### Login screen

```sh
./nordfra/install-gdm.sh     # needs sudo; rerun after GNOME Shell updates
./nordfra/install-gdm.sh -r  # restore the stock login screen
./nordfra/gdm-resource.sh <stock.gresource> <out.gresource>  # only build it, e.g. for packaging
```

## Uninstall

```sh
./nordfra/install.sh -r
```

This restores the backed-up files.

## Development

```sh
./build.sh      # renders the theme into dist/nordfra (needs jq)
mise release    # builds, tags and publishes a release
```

Colours live in [`tokens.json`](tokens.json); templates in [`templates/`](templates/) reference them as `{{ group.key }}`.

Icon glyphs in [`icons/`](icons/) fill the `{{ glyph }}` slot of [`templates/icons/`](templates/icons/). To add one, import it under the app's `Icon=` name (`--silhouette` for a full-colour source):

```sh
scripts/import-glyph.py /usr/share/icons/hicolor/symbolic/apps/org.gnome.Maps-symbolic.svg icons/apps/org.gnome.Maps.svg
```

File icons in [`icons/mimetypes/`](icons/mimetypes/) are Adwaita's, recoloured with `scripts/import-mimetype.py`.

The Shell theme targets one GNOME Shell version, pinned as `shell_version` in `scripts/check-shell-selectors.sh`. CI fails if a selector no longer exists in that version.
