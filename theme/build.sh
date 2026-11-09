#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
out=dist/nordix-theme

substitutions_for() {
  jq -r --arg variant "$1" '
    if $variant == "light" then .colors += .colors_light else . end
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
dark icons/index.theme data/icons/nordix/index.theme
EOF

render_shell() {
  mkdir -p "$out/data/themes/$2/gnome-shell"
  {
    sed "$1" templates/shell/themed.css
    echo
    sed "$dark" templates/shell/always-dark.css
  } > "$out/data/themes/$2/gnome-shell/gnome-shell.css"
}
render_shell "$dark" nordix
render_shell "$light" nordix-light

mkdir -p "$out/config/gtk-4.0"
{
  sed "$dark" templates/gtk-4.0.css
  echo
  sed "$dark" templates/gtk-4.0-palette.css
  echo
  sed "$light" templates/gtk-4.0-palette.css
} > "$out/config/gtk-4.0/gtk.css"

scripts/import-glyph.py --check icons/apps/*.svg icons/places/*.svg

compose() {
  template_file=$1 glyph_file=$2
  while IFS= read -r line; do
    if [ "$line" = "{{ glyph }}" ]; then
      cat "$glyph_file"
    else
      printf '%s\n' "$line"
    fi
  done < "templates/icons/$template_file" | sed "$dark"
}

icons=$out/data/icons/nordix/scalable
while read -r context template; do
  mkdir -p "$icons/$context"
  for glyph in "icons/$context"/*.svg; do
    compose "$template" "$glyph" > "$icons/$context/${glyph##*/}"
  done
done <<EOF
apps app.svg
places folder.svg
EOF
mkdir -p "$icons/mimetypes"
scripts/recolour-mimetypes.py "$icons/mimetypes" icons/mimetypes/*.svg
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
