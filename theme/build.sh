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

compose() {
  while IFS= read -r line; do
    if [ "$line" = "{{ glyph }}" ]; then
      sed '1d;$d' "$2"
    else
      printf '%s\n' "$line"
    fi
  done < "templates/icons/$1" | sed "$substitutions"
}

icons=$out/data/icons/nordfra/scalable
mkdir -p "$icons/apps" "$icons/places"
for glyph in icons/apps/*.svg; do
  compose app.svg "$glyph" > "$icons/apps/${glyph##*/}"
done
for glyph in icons/places/*.svg; do
  compose folder.svg "$glyph" > "$icons/places/${glyph##*/}"
done

cp scripts/install.sh scripts/install-gdm.sh scripts/gdm-resource.sh "$out/"

if grep -rlF '{{' "$out" >&2; then
  echo "unresolved placeholders in the files above" >&2
  exit 1
fi

cp tokens.json "$out/tokens.json"
