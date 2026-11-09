#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
config=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}

usage() {
  echo "Usage: $0 [-l | -d | -r]"
  echo "  -l, --light   install and switch GNOME to light mode"
  echo "  -d, --dark    install and switch GNOME to dark mode"
  echo "  -r, --remove  remove nordix and restore the files it backed up"
  echo "Without an option, nordix is installed in the mode of the current Shell theme."
}

shell_theme() {
  case $1 in
    light) echo nordix-light ;;
    *) echo nordix ;;
  esac
}

target_for() {
  case $1 in
    config/*) echo "$config/${1#config/}" ;;
    data/*) echo "$data/${1#data/}" ;;
    variants/*/config/*) echo "$config/${1#variants/*/config/}" ;;
  esac
}

each_file() {
  find config data "variants/$mode/config" -type f | while read -r source; do
    "$1" "$source" "$(target_for "$source")"
  done
}

remove_empty_dirs() {
  find config data "variants/$mode/config" -mindepth 1 -type d | sort -r | while read -r source; do
    rmdir "$(target_for "$source")" 2> /dev/null || true
  done
}

install_file() {
  source=$1 target=$2
  mkdir -p "$(dirname "$target")"
  if [ "${target#"$config"/}" != "$target" ] && [ -f "$target" ] && [ ! -e "$target.nordix-backup" ] &&
    ! grep -qF '/* nordix */' "$target" && ! cmp -s "$source" "$target"; then
    mv "$target" "$target.nordix-backup"
    echo "backed up $target to $target.nordix-backup"
  fi
  cp "$source" "$target"
}

remove_file() {
  target=$2
  rm -f "$target"
  if [ -f "$target.nordix-backup" ]; then
    mv "$target.nordix-backup" "$target"
    echo "restored $target"
  fi
}

reload_icon_theme() {
  command -v gsettings > /dev/null || return 0
  [ "$(gsettings get org.gnome.desktop.interface icon-theme 2> /dev/null)" = "'nordix'" ] || return 0
  gsettings set org.gnome.desktop.interface icon-theme Adwaita || return 0
  sleep 1
  gsettings set org.gnome.desktop.interface icon-theme nordix
}

reload_shell_theme() {
  command -v gsettings > /dev/null || return 0
  theme=$(gsettings get org.gnome.shell.extensions.user-theme name 2> /dev/null) || return 0
  case $theme in
    "'$(shell_theme dark)'" | "'$(shell_theme light)'") ;;
    *) return 0 ;;
  esac
  gsettings set org.gnome.shell.extensions.user-theme name ''
  gsettings set org.gnome.shell.extensions.user-theme name "$(echo "$theme" | tr -d "'")"
}

current_mode() {
  if command -v gsettings > /dev/null &&
    [ "$(gsettings get org.gnome.shell.extensions.user-theme name 2> /dev/null)" = "'$(shell_theme light)'" ]; then
    echo light
  else
    echo dark
  fi
}

apply_mode() {
  if ! command -v gsettings > /dev/null; then
    echo "error: gsettings not found; cannot switch to $mode mode" >&2
    exit 1
  fi
  case $mode in
    light) scheme=prefer-light gtk_theme=adw-gtk3 ;;
    dark) scheme=prefer-dark gtk_theme=adw-gtk3-dark ;;
  esac
  gsettings set org.gnome.desktop.interface color-scheme "$scheme"
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
  if ! gsettings set org.gnome.shell.extensions.user-theme name "$(shell_theme "$mode")" 2> /dev/null; then
    echo "warning: User Themes extension not found; set the Shell theme to $(shell_theme "$mode") yourself" >&2
  fi
  echo "switched to $mode mode; restart open apps"
}

install_theme() {
  each_file install_file
  reload_icon_theme
  reload_shell_theme
  echo "nordix installed ($mode)"
  for theme in "$(shell_theme dark)" "$(shell_theme light)"; do
    if [ -e "$HOME/.themes/$theme" ]; then
      echo "warning: $HOME/.themes/$theme shadows the installed Shell theme; remove it to use this one" >&2
    fi
  done
}

case "${1:-}" in
  "")
    mode=$(current_mode)
    install_theme
    ;;
  -l | --light | -d | --dark)
    case $1 in -l | --light) mode=light ;; *) mode=dark ;; esac
    install_theme
    apply_mode
    ;;
  -r | --remove)
    mode=$(current_mode)
    each_file remove_file
    remove_empty_dirs
    echo "nordix removed"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
