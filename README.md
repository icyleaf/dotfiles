# icyleaf's dotfiles

Personal dotfiles repository built and managed using the [Chezmoi](https://chezmoi.io/) declarative configuration manager. Supports one-key deployment and lifecycle initialization across macOS and Linux (GUI/Headless) environments.

## Installation and Quick Start

### Option 1: Bootstrap Script (Recommended)

The bootstrap script detects your platform, installs the three base utilities (`git`, `chezmoi`, `age`), and then runs `chezmoi init --apply`. Remaining system packages (including `fcitx5-rime`) are installed during apply from `linux-packages.txt` via `pm.sh`:

```bash
git clone https://github.com/icyleaf/dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install.sh
```

> [!IMPORTANT]
> Restore the shared Age private key **before** the first `chezmoi apply` (see [Secret Management](#secret-management-age)), otherwise encrypted secrets will be skipped with warnings.

### Option 2: Remote One-Key Deployment

Directly initialize and apply without manually cloning the repository:

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply icyleaf
```

> [!WARNING]
> This path does **not** run `install.sh`. Ensure `git`, `chezmoi`, and `age` are already installed, and restore the Age key first, or secret deployment will be skipped.

### Option 3: Local Clone Initialization

If you have already cloned this repository locally:

```bash
cd ~/.dotfiles
chezmoi init --source "$PWD" --apply
```

> [!NOTE]
> During the first `init` process, Chezmoi will interactively prompt for your Git name, email, and whether the current system is a GUI-less Headless environment, and automatically render the configurations accordingly.

## Directory Structure

- `dot_config/`: Generic and Linux-specific application configurations (e.g., Hyprland, Waybar, Walker, etc.) deployed to `~/.config/`.
- `dot_local/bin/`: Custom executables and maintenance scripts deployed to `~/.local/bin/`.
- `Library/`: macOS-specific preference files (e.g., Alfred, iTerm2, LinearMouse, etc.) deployed to `~/Library/`.
- `assets/`: Static non-dotfiles repository assets, such as Plymouth themes.

## Integration Testing

Before submitting configuration changes, you can run the integration test script locally to ensure template rendering and installation lifecycles function correctly:

```bash
# Run non-intrusive sandbox testing
./.scratch/verify-chezmoi.sh
```

## Secret Management (Age)

Sensitive private data (SSH keys, environment variables) is managed using Age encryption via Chezmoi's encryption integration and custom lifecycle hooks.

### Prerequisite

Each machine has its own Age key pair. The active identity is resolved at
`chezmoi init` time as `~/.local/share/age/<machine_profile>.txt` when present,
otherwise the shared `~/.local/share/age/default-key.txt`. To use an existing
key, place it at the resolved path before the first apply:

```bash
mkdir -p ~/.local/share/age
cp /path/to/your/backup/<profile>.txt ~/.local/share/age/    # or default-key.txt
chmod 600 ~/.local/share/age/<profile>.txt
```

If no key is present, `run_once_before_setup-age-key.sh` generates one at the
resolved path. A newly generated key **cannot** decrypt existing repository
secrets — restore the matching private key from backup, or add its public key to
`secrets/recipients.txt` and re-encrypt (see below).

### Shared vs Profile Secrets

- `secrets/base/**` — shared by every machine; encrypted to **all** recipients
  listed in `secrets/recipients.txt` (public keys only, safe to commit).
- `secrets/profiles/<profile>/**` — readable by the owning machine alone;
  encrypted to that machine's key.

### Add a Machine (Recipient)

1. On the new machine, print its public key:
   ```bash
   age-keygen -y ~/.local/share/age/<profile>.txt
   ```
2. Append the public key to `secrets/recipients.txt`.
3. Re-encrypt the shared secrets so the new machine can read them:
   ```bash
   scripts/reencrypt-secrets.sh                    # uses ~/.local/share/age/default-key.txt
   scripts/reencrypt-secrets.sh /path/to/key.txt   # or an explicit identity
   ```
4. Commit `secrets/recipients.txt` and the re-encrypted `secrets/base/**`.

### How to Encrypt a New Shared Secret

```bash
age -R secrets/recipients.txt -o secrets/base/foo.age foo
```

### How to Encrypt a New Profile Secret

Encrypt to that profile's public key alone:

```bash
age -r <profile_public_key> -o secrets/profiles/<profile_name>/foo.age foo
```

### How to Edit and Re-encrypt a Secret

```bash
# Shared secret
age -d -i ~/.local/share/age/default-key.txt secrets/base/foo.age > /tmp/foo
nano /tmp/foo
age -R secrets/recipients.txt -o secrets/base/foo.age /tmp/foo
rm /tmp/foo
```

For a profile secret, decrypt with that machine's identity and re-encrypt with
`age -r <profile_public_key>`.

### How to Add a New Secret Profile

1. Create a directory for the new profile:
   ```bash
   mkdir -p secrets/profiles/<profile_name>/ssh
   ```
2. Encrypt the profile's environment variables to that profile's key:
   ```bash
   age -r <profile_public_key> -o secrets/profiles/<profile_name>/local.zsh.age local.zsh
   ```
3. Commit the encrypted `.age` files (never commit the plaintext versions).

### SSH Config Fragments

SSH `Host` entries live in encrypted, reusable fragments instead of a single
plaintext `~/.ssh/config`:

- `secrets/base/ssh_config.d/<group>/<fragment>.conf.age` — shared fragments,
  grouped for organisation (`common`, `homelab`, `tokyo`, `vps`, `work_wst`).
  Every group is deployed to every machine and decrypted to
  `~/.ssh/config.d/<group>_<fragment>.conf`. A fragment the active age identity
  cannot decrypt is skipped. The group name only namespaces the deployed
  filename.
- `secrets/profiles/<profile>/ssh_config.d/<fragment>.conf.age` — fragments
  exclusive to one profile, decrypted to
  `~/.ssh/config.d/<profile>_<fragment>.conf`.

The managed, plaintext `~/.ssh/config` (source: `private_dot_ssh/config`) holds only
`Include config.d/*.conf` plus the global `Host *` defaults.

`run_onchange_deploy-secrets.sh` regenerates `~/.ssh/config.d/*.conf` on every
apply and removes stale fragments, so deleting a `.age` file also removes its
deployed config.

To add a host:

```bash
# 1. Create a plaintext fragment (e.g. secrets/base/ssh_config.d/homelab/20_db.conf)
vim secrets/base/ssh_config.d/homelab/20_db.conf

# 2. Encrypt it into the group, to every recipient like other base secrets
age -R secrets/recipients.txt \
  -o secrets/base/ssh_config.d/homelab/20_db.conf.age \
  secrets/base/ssh_config.d/homelab/20_db.conf
rm secrets/base/ssh_config.d/homelab/20_db.conf   # never commit plaintext

# 3. Deploy
chezmoi apply
```
