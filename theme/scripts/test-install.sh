#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/../dist/nordfra"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
home=$work/home
export HOME="$home" XDG_CONFIG_HOME="$home/config" XDG_DATA_HOME="$home/data" GSETTINGS_BACKEND=memory

fail() {
  echo "test-install: $*" >&2
  exit 1
}

snapshot() {
  (cd "$home" && find . -exec sh -c 'printf "%s " "$1"; [ -f "$1" ] && cksum < "$1" || echo' _ {} \; | sort) > "$work/$1"
}

mkdir -p "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_DATA_HOME/icons/other"
echo "user css" > "$XDG_CONFIG_HOME/gtk-3.0/gtk.css"
echo "[Icon Theme]" > "$XDG_DATA_HOME/icons/other/index.theme"
snapshot before

./install.sh > /dev/null
find config data variants/dark/config -type f | while read -r source; do
  case $source in
    variants/*) target=$XDG_CONFIG_HOME/${source#variants/dark/config/} ;;
    config/*) target=$XDG_CONFIG_HOME/${source#config/} ;;
    data/*) target=$XDG_DATA_HOME/${source#data/} ;;
  esac
  cmp -s "$source" "$target" || fail "$source is not installed at $target"
done
[ "$(cat "$XDG_CONFIG_HOME/gtk-3.0/gtk.css.nordfra-backup")" = "user css" ] || fail "gtk-3.0/gtk.css was not backed up"

snapshot installed
./install.sh > /dev/null
snapshot reinstalled
cmp -s "$work/installed" "$work/reinstalled" || fail "reinstalling changed the installed files"

./install.sh --remove > /dev/null
snapshot removed
diff -u "$work/before" "$work/removed" >&2 || fail "removing left the changes above"

echo "install, reinstall and remove round-trip cleanly"
