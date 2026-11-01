#!/usr/bin/env sh
set -eu

shell_version=50
blur_my_shell_version=72

usage() {
  echo "Usage: $0 [SOURCE_DIR...]"
  echo "  Fails if a class or id in templates/gnome-shell.css is missing from"
  echo "  gnome-shell and gnome-shell-extensions $shell_version and Blur my Shell"
  echo "  v$blur_my_shell_version. Without SOURCE_DIRs, all three are cloned."
}

case "${1:-}" in
  -h | --help)
    usage
    exit
    ;;
esac

cd "$(dirname "$0")/.."
template=$PWD/templates/gnome-shell.css

if [ $# -eq 0 ]; then
  sources=$(mktemp -d)
  trap 'rm -rf "$sources"' EXIT
  for repo in gnome-shell gnome-shell-extensions; do
    git clone --quiet --depth 1 --branch "gnome-$shell_version" \
      "https://gitlab.gnome.org/GNOME/$repo.git" "$sources/$repo"
  done
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v$blur_my_shell_version" \
    https://github.com/aunetx/blur-my-shell.git "$sources/blur-my-shell"
  set -- "$sources/gnome-shell" "$sources/gnome-shell-extensions" "$sources/blur-my-shell"
fi

selectors=$(
  sed 's/{{[^}]*}}//g' "$template" | tr '\n' ' ' \
    | awk 'BEGIN { RS = "}" } { sub(/\{.*/, ""); print }' \
    | grep -oE '[.#][A-Za-z_][A-Za-z0-9_-]*' | cut -c2- | sort -u
)

missing=0
for name in $selectors; do
  if ! grep -rqE --include='*.scss' --include='*.css' --include='*.js' --include='*.c' \
    "(^|[^A-Za-z0-9_-])$name([^A-Za-z0-9_-]|$)" "$@"; then
    echo "not found upstream: $name" >&2
    missing=1
  fi
done

if [ "$missing" -eq 1 ]; then
  echo "templates/gnome-shell.css uses selectors missing from GNOME Shell $shell_version" >&2
  exit 1
fi

echo "all $(echo "$selectors" | wc -l) Shell selectors exist in GNOME Shell $shell_version"
