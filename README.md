<h1 align="center">
  nisse
</h1>

<p align="center">
  Fully automated provision & configuration for fresh Linux installs
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white"/>
  &ensp;
  <img src="https://img.shields.io/badge/Fedora-44-51A2DA?logo=fedora&logoColor=white"/>
  &ensp;
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/nisse?label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/nisse?label=License"/>
  &ensp;
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nisse/nix.yaml?branch=main&label=CI%20NixOS"/>
  &ensp;
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nisse/ansible.yaml?branch=main&label=CI%20Ansible"/>
</p>

> A *nisse* (Norwegian: [ˈnɪ̂sːə]) is a gnome-like household spirit from Nordic culture who, if rewarded with porridge, might help with common chores.

<p align="center">
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#structure">Structure</a> |
  <a href="#development">Development</a>
</p>

## Installation

It is assumed that the autoconfiguration takes place on a freshly installed machine, with a working internet connection and no manual setup beyond that. Installing the operating system and partitioning disks are out of scope, everything from there on is handled here.

> [!IMPORTANT]
> Don't forget to adjust/replace hardcoded values, such as username, git name, ... across the project before running the configuration for the first time.

### NixOS

1. Set up repository

```sh
nix-shell -p git
git clone https://github.com/FjellOverflow/nisse.git ~/.nisse && cd ~/.nisse/nix
```

2. Copy pre-generated configs

> [!NOTE]
> This assumes that the configs generated during installation (`/etc/nixos/configuration.nix` and `/etc/nixos/hardware-configuration.nix`) are still in place.

```sh
mkdir machines/<host>
sudo cp /etc/nixos/configuration.nix machines/<host>/default.nix
sudo cp /etc/nixos/hardware-configuration.nix machines/<host>/hardware-configuration.nix
sudo chown $(whoami): machines/<host>/*
```

3. Adjust `machines/<host>/default.nix` (same pattern as already existing `machines/<existingHost>/default.nix`)

4. Activate config

```sh
git add .
sudo nixos-rebuild switch --flake ~/.nisse/nix#<host>
```

5. Wire in new config, once the activation above succeeded

```sh
sudo rm -rf /etc/nixos
sudo ln -s ~/.nisse/nix /etc/nixos
```

> [!NOTE]
> After symlinking `/etc/nixos` to it, `~/.nisse` should not be deleted or moved, otherwise the symlink needs updating.

### Fedora

> [!NOTE]
> While the Ansible based configuration might work on all Fedora/RHEL based distros, it has only been tested on Fedora.

1. Set up repository

```sh
sudo dnf install -y ansible git
git clone https://github.com/FjellOverflow/nisse.git ~/.nisse && cd ~/.nisse/ansible
ansible-galaxy collection install -r requirements.yaml
```

2. Add the new host to `hosts.yaml`

> [!IMPORTANT]
> The playbook configures the user it connects as, so that user account has to exist already. Creating it is part of installing the operating system and therefore out of scope. When connecting remotely, connect as that user (`ansible_user`), not as `root`.

```yaml
all:
  children:
    workstation:
      hosts:
        <host>:
          ansible_connection: local
```

3. Activate the config by running the playbook

```sh
ansible-playbook site.yml --limit <host> -K
```

### Quick install

Alternatively, the autoconfiguration can be triggered with an automated install script. The script detects the current operating system, clones the repository and runs the applicable configuration. It's interactive and prompts for user inputs at important steps and always asks for confirmation before applying changes.

> [!CAUTION]
> Executing a remote script of unknown origin can be dangerous. Verify that you understand what [`install.sh`](install.sh) does before running it, and do so at your own risk.

```sh
curl -sSL https://raw.githubusercontent.com/FjellOverflow/nisse/main/install.sh | sh
```

## Usage

Once set up, the configuration can be re-run at any time.

1. Update the repository

```sh
cd ~/.nisse && git pull
```

2. Apply new changes

```sh
# on NixOS
cd nix && nh os switch

# on Fedora
cd ansible && ansible-playbook site.yml --limit <host>
```

## Structure

NixOS and Fedora are both configured in four layers, laid out the same way:

| Layer      | NixOS (`nix/`)        | Fedora (`ansible/`) |
| ---------- | --------------------- | ------------------- |
| `base`     | `base/common.nix`     | `base/common/`      |
| `modules`  | `modules/<name>.nix`  | `modules/<name>/`   |
| `profiles` | `profiles/<name>.nix` | `profiles/<name>/`  |
| host       | `machines/<host>/`    | `hosts.yaml`        |

Everything in `base` lands on every machine. A _module_ configures one feature, while a _profile_ bundles modules that belong together. Each machine picks one or more profiles.

Due to fundamental differences between underlying engines, NixOS and Fedora share no code and both parts are kept in sync manually.

## Development

This project is two-fold, containing both _Ansible_ code and _Nix_ code, so depending on which part is worked on, different tools need to be installed.

### Nix

`cd nix` with [direnv](https://direnv.net/) loads a devShell containing `statix`, `deadnix`, `nixfmt` and a `lint` script.

```sh
nix run .#lint    # statix + deadnix + nixfmt
nix flake check   # evaluate configurations
```

### Ansible

- Install the pinned collections with `ansible-galaxy collection install -r requirements.yaml`
- Install [ansible-dev-tools](https://github.com/ansible/ansible-dev-tools)
- Install the [Ansible extension](https://marketplace.visualstudio.com/items?itemName=redhat.ansible) in VS Code.
- In VS Code, search for `ansible validation` in the settings, and enable both _Ansible validation_ and _Ansible validation lint_. Also type `ansible-lint` in the path for _ansible-lint_.

Now all ansible files should get linted on every save. Alternatively, you can run `ansible-lint --fix` on the command line to get a linter report on all project files.

### CI

`.github/workflows/` contains one workflow per engine, so if the changes are restricted to one of the `nix` or `ansible` subdirectories, only the respective CI is run.

- `nix`: `nix run .#lint`, `nix flake check`
- `ansible`: `ansible-lint`

While the CI can't verify actual runtime behaviour, a green run signals well-formed & formatted code, and for NixOS that all configurations evaluate.
