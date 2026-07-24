<h1 align="center">
  Ansible Fedora Setup
</h1>

<p align="center">
  Straightforward ansible playbooks that set up a fresh Fedora install.
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/tag/FjellOverflow/ansible-fedora-setup?label=Version"/>
  &ensp;
  <img src="https://img.shields.io/github/license/FjellOverflow/ansible-fedora-setup?label=License"/>
  &ensp;
  <img src="https://img.shields.io/github/actions/workflow/status/FjellOverflow/ansible-fedora-setup/lint.yaml?branch=main&label=CI"/>
</p>

A straightforward ansible playbook that sets up a fresh Fedora (Workstation edition, >= 42) install. Adds & removes packages, sets up shell, tweaks GNOME & more.

## Usage

1. Install `ansible`

```bash
sudo dnf install -y ansible
```

2. Clone this repository

```bash
git clone https://github.com/FjellOverflow/ansible-fedora-setup.git && cd ansible-fedora-setup
```

3. Declare the target host in `hosts.yaml` under its profile group (see the `vm` example). For the local machine set `ansible_connection: local`; for a remote host set its `ansible_host` / `ansible_user` and copy your SSH key with `ssh-copy-id`.

4. Run the playbook for that host

```bash
ansible-playbook site.yml --limit <host> -K
```

## Development

To develop this project within VS Code:

- Install [ansible-dev-tools](https://github.com/ansible/ansible-dev-tools)
- Install the [Ansible extension](https://marketplace.visualstudio.com/items?itemName=redhat.ansible) in VS Code.
- In VS Code, search for `ansible validation` in the settings, and enable both *Ansible validation* and *Ansible validation lint*. Also type `ansible-lint` in the path for *ansible-lint*.

Now all ansible files should get linted on every save. Alternatively, you can run `ansible-lint --fix` on the command line to get a linter report on all project files.

To also lint on every commit, enable the git pre-commit hook (runs `ansible-lint`, same as CI):

```bash
pip install pre-commit
pre-commit install
```
