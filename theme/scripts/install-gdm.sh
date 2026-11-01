#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
target=/usr/share/gnome-shell/gnome-shell-theme.gresource
backup=$target.nordfra-backup
prefix=/org/gnome/shell/theme
marker='/* nordfra: login screen */'

as_root() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# Our resource is uncompressed, so the marker shows up in the raw file.
is_themed() {
  grep -qaF "$marker" "$target"
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
    echo "error: $backup is missing; reinstall gnome-shell to restore the original" >&2
    exit 1
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  paths=$(gresource list "$backup")

  for path in $paths; do
    gresource extract "$backup" "$path" > "$work/${path#"$prefix"/}"
  done
  if [ ! -s "$work/gnome-shell-dark.css" ]; then
    echo "error: $backup has no gnome-shell-dark.css" >&2
    exit 1
  fi
  printf '\n%s\n' "$marker" >> "$work/gnome-shell-dark.css"
  cat data/themes/nordfra/gnome-shell/gnome-shell.css >> "$work/gnome-shell-dark.css"

  {
    echo "<gresources><gresource prefix=\"$prefix\">"
    for path in $paths; do
      echo "<file>${path#"$prefix"/}</file>"
    done
    echo '</gresource></gresources>'
  } > "$work/theme.xml"

  glib-compile-resources --sourcedir="$work" --target="$work/theme.gresource" "$work/theme.xml"
  as_root install -m 644 "$work/theme.gresource" "$target"
  echo "login screen themed; log out to see it"
}

restore() {
  [ -f "$backup" ] || return 0
  if is_themed; then
    as_root mv "$backup" "$target"
    echo "login screen restored"
  else
    as_root rm "$backup"
  fi
}

case "${1:-}" in
  "") theme ;;
  -r | --remove) restore ;;
  *)
    echo "Usage: $0 [-r]" >&2
    exit 1
    ;;
esac
