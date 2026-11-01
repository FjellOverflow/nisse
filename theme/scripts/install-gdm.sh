#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
target=/usr/share/gnome-shell/gnome-shell-theme.gresource
backup=$target.nordfra-backup
# Must match the marker in gdm-resource.sh.
marker='/* nordfra: login screen */'

usage() {
  echo "Usage: $0 [-r]"
  echo "  -r, --remove  restore the stock login screen"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# gdm-resource.sh compiles uncompressed, so the marker shows up in the raw file.
is_themed() {
  grep -qaF "$marker" "$target"
}

missing_backup() {
  echo "error: $backup is missing; reinstall gnome-shell to restore the original" >&2
  exit 1
}

ensure_tools() {
  command -v gresource > /dev/null && command -v glib-compile-resources > /dev/null && return
  if command -v dnf > /dev/null; then
    set -- dnf install glib2-devel
  elif command -v apt-get > /dev/null; then
    set -- apt-get install libglib2.0-bin libglib2.0-dev-bin
  elif command -v pacman > /dev/null; then
    set -- pacman -S --needed glib2
  else
    echo "error: install gresource and glib-compile-resources with your package manager" >&2
    exit 1
  fi
  echo "installing gresource and glib-compile-resources with $1"
  as_root "$@"
}

theme() {
  ensure_tools

  # A GNOME Shell update replaces our file; only then refresh the backup.
  if ! is_themed; then
    as_root cp "$target" "$backup"
  elif [ ! -f "$backup" ]; then
    missing_backup
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  ./gdm-resource.sh "$backup" "$work/theme.gresource"

  if cmp -s "$work/theme.gresource" "$target"; then
    echo "login screen already up to date"
    return
  fi

  as_root install -m 644 "$work/theme.gresource" "$target.nordfra-new"
  as_root mv "$target.nordfra-new" "$target"
  echo "login screen themed; log out to see it"
}

restore() {
  if is_themed; then
    [ -f "$backup" ] || missing_backup
    as_root mv "$backup" "$target"
    echo "login screen restored"
  elif [ -f "$backup" ]; then
    as_root rm "$backup"
  fi
}

case "${1:-}" in
  "") theme ;;
  -r | --remove) restore ;;
  -h | --help) usage ;;
  *)
    usage >&2
    exit 1
    ;;
esac
