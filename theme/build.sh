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
EOF

cp scripts/install.sh scripts/install-gdm.sh scripts/gdm-resource.sh "$out/"

if grep -rlF '{{' "$out" >&2; then
  echo "unresolved placeholders in the files above" >&2
  exit 1
fi

cp tokens.json "$out/tokens.json"
