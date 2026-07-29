#!/usr/bin/env sh

# curl -sSL https://raw.githubusercontent.com/FjellOverflow/nisse/main/install.sh | sh

set -eu

REPO=https://github.com/FjellOverflow/nisse
CHECKOUT=$HOME/.nisse
CHECKOUT_SHORT='~/.nisse'
README=$REPO#installation

step() { printf '==> %s\n' "$*"; }

die() {
  printf '!! %s\n' "$*" >&2
  exit 1
}

ask() {
  printf '\n%s ' "$*" >/dev/tty
  IFS= read -r reply </dev/tty || reply=
}

confirm() {
  ask "$*"
  case $reply in
  [Yy]*) ;;
  *)
    printf '\nExited without applying configuration. Re-run script once you are ready or read more at %s\n\n' "$README"
    exit 0
    ;;
  esac
}

find_editor() {
  EDITOR=${EDITOR:-}
  command -v "$EDITOR" >/dev/null 2>&1 || EDITOR=''
  [ -n "$EDITOR" ] && return 0
  for e in nano vim vi; do
    if command -v "$e" >/dev/null 2>&1; then
      EDITOR=$e
      return 0
    fi
  done
}

edit_files() {
  if [ -n "$EDITOR" ]; then
    ask "Edit file(s) with $EDITOR? [Y/n]"
    case $reply in
    [Nn]*) ;;
    *)
      for f in "$@"; do
        "$EDITOR" "$f" </dev/tty >/dev/tty 2>&1 || true
      done
      return
      ;;
    esac
  fi
  ask 'Confirm with Enter once you are done editing.'
}

git_run() {
  if [ "$ID" = nixos ]; then
    nix-shell -p git --run "git $*"
  else
    git "$@"
  fi
}

clone() {
  if [ -e "$CHECKOUT" ]; then
    grep -qF "$REPO" "$CHECKOUT/.git/config" 2>/dev/null ||
      die 'Found malformed local repository. Inspect, fix and re-run script.'
    if git_run -C "$CHECKOUT" pull --ff-only; then
      step 'Found local version of repository.'
    else
      step 'Repository has local changes, skipped updating.'
    fi
    return
  fi
  git_run clone "$REPO" "$CHECKOUT"
  step 'Cloned repository.'
}

ask_host() {
  default=$(uname -n | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
  ask "Choose name for this host: [$default]"
  [ -n "$reply" ] || reply=$default
  host=$(printf '%s' "$reply" | tr '[:upper:]' '[:lower:]')
  case $host in
  *[!a-z0-9-]*) die 'Host name may only contain lowercase letters, digits and dashes.' ;;
  esac
}

bootstrap_fedora() {
  sudo dnf install -y ansible git
  step 'Installed ansible, git.'

  clone
  ask_host

  (cd "$CHECKOUT/ansible" && ansible-galaxy collection install -r requirements.yaml)
  step 'Installed ansible collections.'

  printf '\nBefore the installation proceeds, add host %s to ansible/hosts.yaml.\n' "$host" >/dev/tty
  edit_files "$CHECKOUT/ansible/hosts.yaml"

  confirm "The configuration is about to be applied. This may take a while.

     ansible-playbook site.yml --limit $host -K

Continue? [y/N]"

  (cd "$CHECKOUT/ansible" && ansible-playbook site.yml --limit "$host" -K </dev/tty) ||
    die 'Ansible exited with error. The machine may be in a partially configured state. Inspect and fix the error, then re-run the script.'
  step "Host $host was successfully configured."

  cat <<EOF

You can re-apply this configuration again at any point with

     cd $CHECKOUT_SHORT && git pull
     cd ansible && ansible-playbook site.yml --limit $host

Read more at $README

EOF
}

bootstrap_nixos() {
  clone
  ask_host

  machine=$CHECKOUT/nix/machines/$host
  if [ -e "$machine" ]; then
    step "Using already existing configuration at nix/machines/$host."
  else
    for f in configuration.nix hardware-configuration.nix; do
      [ -f "/etc/nixos/$f" ] || die "/etc/nixos/$f is missing, regenerate it with nixos-generate-config."
    done
    mkdir -p "$machine"
    cp /etc/nixos/configuration.nix "$machine/default.nix"
    cp /etc/nixos/hardware-configuration.nix "$machine/hardware-configuration.nix"
    step "Copied pre-generated configuration to nix/machines/$host."
  fi

  cat >/dev/tty <<EOF

Before the installation proceeds, adjust nix/machines/$host/default.nix (see existing machines for reference) and add new host to nix/flake.nix.
EOF
  edit_files "$machine/default.nix" "$CHECKOUT/nix/flake.nix"

  git_run -C "$CHECKOUT" add .
  step 'Added new configuration files.'

  confirm "The configuration is about to be applied. This may take a while.

     sudo nixos-rebuild switch --flake $CHECKOUT_SHORT/nix#$host
     sudo rm -rf /etc/nixos && sudo ln -s $CHECKOUT_SHORT/nix /etc/nixos

Continue? [y/N]"

  sudo nixos-rebuild switch --flake "$CHECKOUT/nix#$host" ||
    die 'NixOS exited with error. The machine remained in its previous state. Inspect and fix the error, then re-run the script.'
  step "Host $host was successfully configured."

  sudo rm -rf /etc/nixos
  sudo ln -s "$CHECKOUT/nix" /etc/nixos
  step "Symlinked /etc/nixos to $CHECKOUT_SHORT/nix."

  cat <<EOF

You can re-apply this configuration again at any point with

     cd $CHECKOUT_SHORT && git pull
     nh os switch

Read more at $README

EOF
}

(: </dev/tty) 2>/dev/null || die 'Terminal is non-interactive.'
[ -r /etc/os-release ] || die 'Could not identify OS.'

. /etc/os-release

find_editor

case ${ID:-} in
fedora)
  step 'Detected Fedora.'
  bootstrap_fedora
  ;;
nixos)
  step 'Detected NixOS.'
  bootstrap_nixos
  ;;
*) die "Distribution ${ID:-unknown} is not supported." ;;
esac
