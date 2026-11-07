<h1 align="center">
  <img src="./.github/logo.svg" height="64" align="middle" alt="" />
  &nbsp;nisse
</h1>

<p align="center">
  Fully automated provision & configuration for fresh NixOS installs
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NixOS-26.05-5277C3?logo=nixos&logoColor=white"/>
  &ensp;
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/nisse/nix.yaml?branch=main&label=CI"/>
  &ensp;
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/nisse?label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/nisse?label=License"/>
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
> Don't forget to adjust/replace hardcoded values in [`variables.nix`](variables.nix) before running the configuration for the first time.

1. Set up repository

```sh
nix-shell -p git
git clone https://github.com/FjellOverflow/nisse.git ~/.nisse && cd ~/.nisse
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
sudo nixos-rebuild switch --flake ~/.nisse#<host>
```

5. Wire in new config, once the activation above succeeded

```sh
sudo rm -rf /etc/nixos
sudo ln -s ~/.nisse /etc/nixos
```

> [!NOTE]
> After symlinking `/etc/nixos` to it, `~/.nisse` should not be deleted or moved, otherwise the symlink needs updating.

## Usage

Once set up, the configuration can be re-run at any time.

1. Update the repository

```sh
cd ~/.nisse && git pull
```

2. Apply new changes

```sh
nh os switch
```

## Structure

The configuration is organized in four layers:

| Layer      | Path                  |
| ---------- | --------------------- |
| `base`     | `base/common.nix`     |
| `modules`  | `modules/<name>.nix`  |
| `profiles` | `profiles/<name>.nix` |
| host       | `machines/<host>/`    |

Everything in `base` lands on every machine. A _module_ configures one feature and owns everything about it (package, enable, settings); `theme.nix` owns everything visual. A _profile_ bundles modules that belong together, plus the odd one-liner that doesn't deserve a module. A machine holds hardware facts and picks one or more profiles.

`theme/` is the [nordfra](theme/README.md) GNOME theme. It is self-contained and Nix-free (`cd theme && ./build.sh` needs only `sh`, `jq` and `python3`) and ships its own tagged release tarballs (`theme-vX.Y.Z`) for non-NixOS machines. `flake.nix` builds it as `.#theme`, and `modules/theme.nix` reads only that build plus `theme/tokens.json`.

## Development

With [direnv](https://direnv.net/), the repository root loads a devShell containing `statix`, `deadnix`, `nixfmt`, a `lint` script, and `jq`, `python3` and `shellcheck` for `theme/`.

```sh
nix run .#lint    # statix + deadnix + nixfmt
nix flake check   # evaluate configurations
nix build .#theme # build theme/ in the Nix sandbox
```

### CI

`.github/workflows/nix.yaml` runs `nix run .#lint`, `nix flake check` and `nix build .#theme` on every change except Markdown-only ones. `.github/workflows/theme.yaml` builds, tests and shellchecks `theme/` without Nix whenever it changes, and `theme-release.yaml` publishes a release for every `theme-v*` tag.

While the CI can't verify actual runtime behaviour, a green run signals well-formed & formatted code and that all configurations evaluate.
