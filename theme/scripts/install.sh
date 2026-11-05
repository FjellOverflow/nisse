#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
config=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}

usage() {
  echo "Usage: $0 [-r]"
  echo "  -r, --remove  remove nordfra and restore the files it backed up"
}

each_file() {
  find config data -type f | while read -r source; do
    case $source in
      config/*) target="$config/${source#config/}" ;;
      data/*) target="$data/${source#data/}" ;;
    esac
    "$1" "$source" "$target"
  done
}

install_file() {
  source=$1 target=$2
  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ] && [ ! -e "$target.nordfra-backup" ] && ! cmp -s "$source" "$target"; then
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

case "${1:-}" in
  "")
    each_file install_file
    echo "nordfra installed"
    if [ -e "$HOME/.themes/nordfra" ]; then
      echo "warning: $HOME/.themes/nordfra shadows the installed Shell theme; remove it to use this one" >&2
    fi
    ;;
  -r | --remove)
    each_file remove_file
    rmdir "$data/themes/nordfra/gnome-shell" "$data/themes/nordfra" 2> /dev/null || true
    rmdir "$data/icons/nordfra/scalable/apps" "$data/icons/nordfra/scalable/places" \
      "$data/icons/nordfra/scalable" "$data/icons/nordfra" 2> /dev/null || true
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
