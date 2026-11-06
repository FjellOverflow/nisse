#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
out=dist/nordfra

substitutions=$(jq -r '
  to_entries[]
  | if (.value | type) == "object"
    then .key as $group | .value | to_entries[] | .key = "\($group)\\.\(.key)"
    else . end
  | "s|{{ \(.key) }}|\(.value | gsub("(?<c>[\\\\|&])"; "\\\(.c)"))|g"
' tokens.json)

rm -rf dist
mkdir -p "$out"

while read -r template target; do
  mkdir -p "$out/$(dirname "$target")"
  sed "$substitutions" "templates/$template" > "$out/$target"
done <<EOF
gtk-3.0.css config/gtk-3.0/gtk.css
gtk-4.0.css config/gtk-4.0/gtk.css
gnome-shell.css data/themes/nordfra/gnome-shell/gnome-shell.css
icons/index.theme data/icons/nordfra/index.theme
EOF

require_glyph() {
  if [ "$(head -n 1 "$1")" != '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">' ] ||
    [ "$(tail -n 1 "$1")" != '</svg>' ]; then
    echo "$1: not a glyph; create it with scripts/import-glyph.py" >&2
    exit 1
  fi
}

without_svg_wrapper() {
  sed '1d;$d' "$1"
}

compose() {
  template_file=$1 glyph_file=$2
  while IFS= read -r line; do
    if [ "$line" = "{{ glyph }}" ]; then
      without_svg_wrapper "$glyph_file"
    else
      printf '%s\n' "$line"
    fi
  done < "templates/icons/$template_file" | sed "$substitutions"
}

icons=$out/data/icons/nordfra/scalable
while read -r context template; do
  mkdir -p "$icons/$context"
  for glyph in "icons/$context"/*.svg; do
    require_glyph "$glyph"
    compose "$template" "$glyph" > "$icons/$context/${glyph##*/}"
  done
done <<EOF
apps app.svg
places folder.svg
EOF
mkdir -p "$icons/mimetypes"
cp icons/mimetypes/*.svg "$icons/mimetypes/"
while read -r alias source; do
  cp "$icons/$source" "$icons/mimetypes/$alias.svg"
done <<EOF
inode-directory places/folder.svg
x-office-address-book mimetypes/x-office-addressbook.svg
text-x-generic-template mimetypes/text-x-generic.svg
EOF

cp scripts/install.sh scripts/install-gdm.sh scripts/gdm-resource.sh "$out/"

if grep -rlF '{{' "$out" >&2; then
  echo "unresolved placeholders in the files above" >&2
  exit 1
fi

cp tokens.json "$out/tokens.json"
