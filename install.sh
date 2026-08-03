#!/usr/bin/env sh

# curl -sSL https://raw.githubusercontent.com/FjellOverflow/nisse/main/install.sh | sh

set -eu

REPO=https://github.com/FjellOverflow/nisse
CHECKOUT=$HOME/.nisse
CHECKOUT_SHORT='~/.nisse'
README=$REPO#installation

BANNER='              .@@@@@@@@
           =@@@%      @@@%
         @@@*           #@@
       %@@:           #@@@@@
      @@*             :@@
     @@                @@%
    @@-                 @@
   :@@                  @@%
   @@:                  .@@
   @@                    @@
  %@@                    @@%
  @@.                    .@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@+
#@@     +%@@       @@+:    @@-
@@        @@@@  @@@@        @@
@@=@@        #@@*        .@%@@
@@@@.                    .@@@@
 @@@.                     @@
  *@@@@                @@*@@
   @@@@@              :@@@@
      @@=             @@.@
       @@@           @@:
        %@@:       @@@
          %@@@  -@@@:
             @@@@*'

if [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
  PRIMARY=$(printf '\033[1;36m')
  INFO=$(printf '\033[36m')
  ACCENT=$(printf '\033[1;33m')
  ERROR=$(printf '\033[1;31m')
  RESET=$(printf '\033[0m')
else
  PRIMARY='' INFO='' ACCENT='' ERROR='' RESET=''
fi

banner() { printf '\n%s%s%s\n\n' "$PRIMARY" "$BANNER" "$RESET" >/dev/tty; }

step() { printf '%s==> %s%s\n' "$PRIMARY" "$*" "$RESET" >/dev/tty; }

say() { printf '\n%s%s%s\n' "$INFO" "$*" "$RESET" >/dev/tty; }

cmd() {
  printf '\n' >/dev/tty
  printf '%s\n' "$*" | while IFS= read -r line; do
    printf '     %s%s%s\n' "$PRIMARY" "$line" "$RESET" >/dev/tty
  done
}

die() {
  printf '%s!! %s%s\n' "$ERROR" "$*" "$RESET" >&2
  exit 1
}

ask() {
  printf '\n%s%s%s ' "$ACCENT" "$*" "$RESET" >/dev/tty
  IFS= read -r reply </dev/tty || reply=
}

confirm() {
  ask "$*"
  case $reply in
  [Yy]*) ;;
  *)
    say "Exited without applying configuration. Re-run script once you are ready or read more at $README"
    printf '\n' >/dev/tty
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
      step 'Could not update repository, continuing with local version.'
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

  say "Before the installation proceeds, adjust variables and add host $host to ansible/hosts.yaml."
  edit_files "$CHECKOUT/ansible/group_vars/all.yml" "$CHECKOUT/ansible/hosts.yaml"

  say 'The configuration is about to be applied. This may take a while.'
  cmd "ansible-playbook site.yml --limit $host -K"
  confirm 'Continue? [y/N]'

  (cd "$CHECKOUT/ansible" && ansible-playbook site.yml --limit "$host" -K </dev/tty) ||
    die 'Ansible exited with error. The machine may be in a partially configured state. Inspect and fix the error, then re-run the script.'
  step "Host $host was successfully configured."

  say 'You can re-apply this configuration again at any point with'
  cmd "cd $CHECKOUT_SHORT && git pull
cd ansible && ansible-playbook site.yml --limit $host"
  say "Read more at $README"
  printf '\n' >/dev/tty
}

scaffold_machine() {
  state=26.05
  {
    printf '{ user, ... }:\n\n{\n'
    printf '  imports = [\n    ./hardware-configuration.nix\n    ../../profiles/workstation.nix\n  ];\n\n'
    printf '  # TODO: add boot.loader.*, and boot.initrd.luks.* if this machine is encrypted\n\n'
    printf '  networking.hostName = "%s";\n\n' "$host"
    printf '  # TODO: adjust if this machine was installed with a different release\n'
    printf '  system.stateVersion = "%s";\n' "$state"
    printf '  home-manager.users.${user}.home.stateVersion = "%s";\n}\n\n' "$state"
    printf '# TODO: autogenerated config below, keep only what is not in base/common.nix or the available profiles\n\n'
    cat /etc/nixos/configuration.nix
  } >"$machine/default.nix"
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
    cp /etc/nixos/hardware-configuration.nix "$machine/hardware-configuration.nix"
    scaffold_machine
    step "Generated nix/machines/$host from the pre-generated configuration."
  fi

  say "Before the installation proceeds, adjust variables and resolve the TODOs in nix/machines/$host/default.nix (see existing machines for reference)."
  edit_files "$CHECKOUT/nix/variables.nix" "$machine/default.nix"

  git_run -C "$CHECKOUT" add .
  step 'Added new configuration files.'

  say 'The configuration is about to be applied. This may take a while.'
  cmd "sudo nixos-rebuild switch --flake $CHECKOUT_SHORT/nix#$host
sudo rm -rf /etc/nixos && sudo ln -s $CHECKOUT_SHORT/nix /etc/nixos"
  confirm 'Continue? [y/N]'

  sudo nixos-rebuild switch --flake "$CHECKOUT/nix#$host" ||
    die 'NixOS exited with error. The machine remained in its previous state. Inspect and fix the error, then re-run the script.'
  step "Host $host was successfully configured."

  sudo rm -rf /etc/nixos
  sudo ln -s "$CHECKOUT/nix" /etc/nixos
  step "Symlinked /etc/nixos to $CHECKOUT_SHORT/nix."

  say 'You can re-apply this configuration again at any point with'
  cmd "cd $CHECKOUT_SHORT && git pull
nh os switch"
  say "Read more at $README"
  printf '\n' >/dev/tty
}

(: </dev/tty) 2>/dev/null || die 'Terminal is non-interactive.'

step 'Starting'
banner

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
