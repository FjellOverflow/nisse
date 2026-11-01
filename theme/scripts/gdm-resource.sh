#!/usr/bin/env sh
set -eu

release_dir=$(dirname "$0")
prefix=/org/gnome/shell/theme
marker='/* nordfra: login screen */'

if [ $# -ne 2 ]; then
  echo "Usage: $0 <stock.gresource> <out.gresource>" >&2
  exit 1
fi
stock=$1
out=$2

if gresource extract "$stock" "$prefix/gnome-shell-dark.css" | grep -qF "$marker"; then
  echo "error: $stock is already themed; pass the stock resource" >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stylesheet=$work/gnome-shell-dark.css

echo "<gresources><gresource prefix=\"$prefix\">" > "$work/theme.xml"
for path in $(gresource list "$stock"); do
  file=${path#"$prefix"/}
  gresource extract "$stock" "$path" > "$work/$file"
  echo "<file>$file</file>" >> "$work/theme.xml"
done
echo '</gresource></gresources>' >> "$work/theme.xml"

if [ ! -s "$stylesheet" ]; then
  echo "error: $stock has no gnome-shell-dark.css" >&2
  exit 1
fi
printf '\n%s\n' "$marker" >> "$stylesheet"
cat "$release_dir/data/themes/nordfra/gnome-shell/gnome-shell.css" >> "$stylesheet"

glib-compile-resources --sourcedir="$work" --target="$work/theme.gresource" "$work/theme.xml"
if ! gresource extract "$work/theme.gresource" "$prefix/gnome-shell-dark.css" | grep -qF "$marker"; then
  echo "error: the rebuilt theme failed verification" >&2
  exit 1
fi

cp "$work/theme.gresource" "$out"
