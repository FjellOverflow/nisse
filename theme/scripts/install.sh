#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
config=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}

usage() {
  echo "Usage: $0 [-l | -d | -r]"
  echo "  -l, --light   install and switch GNOME to light mode"
  echo "  -d, --dark    install and switch GNOME to dark mode"
  echo "  -r, --remove  remove nordfra and restore the files it backed up"
  echo "Without an option, nordfra is installed in the mode of the current Shell theme."
}

each_file() {
  find config data "variants/$mode" -type f | while read -r source; do
    case $source in
      config/*) target="$config/${source#config/}" ;;
      data/*) target="$data/${source#data/}" ;;
      variants/*/config/*) target="$config/${source#variants/*/config/}" ;;
    esac
    "$1" "$source" "$target"
  done
}

install_file() {
  source=$1 target=$2
  mkdir -p "$(dirname "$target")"
  if [ "${target#"$config"/}" != "$target" ] && [ -f "$target" ] && [ ! -e "$target.nordfra-backup" ] &&
    ! grep -qF '/* nordfra */' "$target" && ! cmp -s "$source" "$target"; then
    mv "$target" "$target.nordfra-backup"
    echo "backed up $target to $target.nordfra-backup"
  fi
  cp "$source" "$target"
}

remove_file() {
  target=$2
  rm -f "$target"
  if [ -f "$target.nordfra-backup" ]; then
    mv "$target.nordfra-backup" "$target"
    echo "restored $target"
  fi
}

reload_icon_theme() {
  command -v gsettings > /dev/null || return 0
  [ "$(gsettings get org.gnome.desktop.interface icon-theme 2> /dev/null)" = "'nordfra'" ] || return 0
  gsettings set org.gnome.desktop.interface icon-theme Adwaita || return 0
  sleep 1
  gsettings set org.gnome.desktop.interface icon-theme nordfra
}

reload_shell_theme() {
  command -v gsettings > /dev/null || return 0
  theme=$(gsettings get org.gnome.shell.extensions.user-theme name 2> /dev/null) || return 0
  case $theme in
    "'nordfra'" | "'nordfra-light'") ;;
    *) return 0 ;;
  esac
  gsettings set org.gnome.shell.extensions.user-theme name ''
  gsettings set org.gnome.shell.extensions.user-theme name "$(echo "$theme" | tr -d "'")"
}

current_mode() {
  if command -v gsettings > /dev/null &&
    [ "$(gsettings get org.gnome.shell.extensions.user-theme name 2> /dev/null)" = "'nordfra-light'" ]; then
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
    light) scheme=prefer-light gtk_theme=adw-gtk3 shell_theme=nordfra-light ;;
    dark) scheme=prefer-dark gtk_theme=adw-gtk3-dark shell_theme=nordfra ;;
  esac
  gsettings set org.gnome.desktop.interface color-scheme "$scheme"
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
  if ! gsettings set org.gnome.shell.extensions.user-theme name "$shell_theme" 2> /dev/null; then
    echo "warning: User Themes extension not found; set the Shell theme to $shell_theme yourself" >&2
  fi
  echo "switched to $mode mode; restart open apps"
}

install_theme() {
  each_file install_file
  reload_icon_theme
  reload_shell_theme
  echo "nordfra installed ($mode)"
  for theme in nordfra nordfra-light; do
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
    rmdir "$data/themes/nordfra/gnome-shell" "$data/themes/nordfra" \
      "$data/themes/nordfra-light/gnome-shell" "$data/themes/nordfra-light" 2> /dev/null || true
    rmdir "$data/icons/nordfra/scalable/apps" "$data/icons/nordfra/scalable/places" \
      "$data/icons/nordfra/scalable/mimetypes" "$data/icons/nordfra/scalable" "$data/icons/nordfra" 2> /dev/null || true
    echo "nordfra removed"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
