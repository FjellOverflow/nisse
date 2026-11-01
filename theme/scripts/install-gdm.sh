#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
target=/usr/share/gnome-shell/gnome-shell-theme.gresource
backup=$target.nordfra-backup
prefix=/org/gnome/shell/theme
marker='/* nordfra: login screen */'

usage() {
  echo "Usage: $0 [-r]"
  echo "  -r, --remove  restore the stock login screen"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# Our resource is uncompressed, so the marker shows up in the raw file.
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
  stylesheet=$work/gnome-shell-dark.css
  paths=$(gresource list "$backup")

  echo "<gresources><gresource prefix=\"$prefix\">" > "$work/theme.xml"
  for path in $paths; do
    file=${path#"$prefix"/}
    gresource extract "$backup" "$path" > "$work/$file"
    echo "<file>$file</file>" >> "$work/theme.xml"
  done
  echo '</gresource></gresources>' >> "$work/theme.xml"

  if [ ! -s "$stylesheet" ]; then
    echo "error: $backup has no gnome-shell-dark.css" >&2
    exit 1
  fi
  printf '\n%s\n' "$marker" >> "$stylesheet"
  cat data/themes/nordfra/gnome-shell/gnome-shell.css >> "$stylesheet"

  glib-compile-resources --sourcedir="$work" --target="$work/theme.gresource" "$work/theme.xml"
  if ! gresource extract "$work/theme.gresource" "$prefix/gnome-shell-dark.css" | grep -qF "$marker"; then
    echo "error: the rebuilt theme failed verification; $target is unchanged" >&2
    exit 1
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
