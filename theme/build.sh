#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
out=dist/nordfra

substitutions_for() {
  jq -r --arg variant "$1" '
    .dark = .colors
    | if $variant == "light" then .colors += .colors_light else . end
    | del(.colors_light)
    | .variant = $variant
    | to_entries[]
    | if (.value | type) == "object"
      then .key as $group | .value | to_entries[] | .key = "\($group)\\.\(.key)"
      else . end
    | "s|{{ \(.key) }}|\(.value | gsub("(?<c>[\\\\|&])"; "\\\(.c)"))|g"
  ' tokens.json
}
dark=$(substitutions_for dark)
light=$(substitutions_for light)

rm -rf dist
mkdir -p "$out"

while read -r variant template target; do
  mkdir -p "$out/$(dirname "$target")"
  sed "$(substitutions_for "$variant")" "templates/$template" > "$out/$target"
done <<EOF
dark gtk-3.0.css variants/dark/config/gtk-3.0/gtk.css
light gtk-3.0.css variants/light/config/gtk-3.0/gtk.css
dark gnome-shell.css data/themes/nordfra/gnome-shell/gnome-shell.css
light gnome-shell.css data/themes/nordfra-light/gnome-shell/gnome-shell.css
dark icons/index.theme data/icons/nordfra/index.theme
EOF

mkdir -p "$out/config/gtk-4.0"
{
  sed "$dark" templates/gtk-4.0.css
  echo
  sed "$dark" templates/gtk-4.0-palette.css
  echo
  sed "$light" templates/gtk-4.0-palette.css
} > "$out/config/gtk-4.0/gtk.css"

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
  done < "templates/icons/$template_file" | sed "$dark"
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
