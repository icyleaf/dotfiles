# icyleaf's dotfiles

Personal dotfiles repository built and managed using the [Chezmoi](https://chezmoi.io/) declarative configuration manager. Supports one-key deployment and lifecycle initialization across macOS and Linux (GUI/Headless) environments.

## Installation and Quick Start

### Option 1: Remote One-Key Deployment (Recommended)

Chezmoi allows you to initialize and apply configuration directly without manually cloning the repository:

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply icyleaf
```

### Option 2: Local Clone Initialization

If you have already cloned this repository locally:

```bash
# Enter the repository directory and use the local chezmoi binary to initialize and deploy
cd ~/.dotfiles
./bin/chezmoi init --source "$PWD" --apply
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

Before running `chezmoi apply` for the first time, you must ensure the shared Age private key is present in your home directory:

```bash
mkdir -p ~/.local/share/age
cp /path/to/your/backup/default-key.txt ~/.local/share/age/default-key.txt
chmod 600 ~/.local/share/age/default-key.txt
```

If it is not present on the first apply, the bootstrap script `run_once_setup-age-key.sh.tmpl` will automatically generate a new key pair at `~/.local/share/age/default-key.txt`.

### How to Encrypt a New File

All encrypted secrets reside in the `secrets/` directory.

To encrypt a new secret (e.g., a file `foo` in a profile directory):

```bash
age -r age1r7hzm4zqsyu880e3f8yn97g7d6jqtxaeg8jjk2xpzqv2d9zgkelq00nmxn -o secrets/profiles/<profile_name>/foo.age foo
```

### How to Edit and Re-encrypt Secrets

To edit an existing encrypted file:

```bash
# Decrypt, edit, and re-encrypt
age -d -i ~/.local/share/age/default-key.txt secrets/profiles/<profile_name>/foo.age > /tmp/foo
nano /tmp/foo
age -r age1r7hzm4zqsyu880e3f8yn97g7d6jqtxaeg8jjk2xpzqv2d9zgkelq00nmxn -o secrets/profiles/<profile_name>/foo.age /tmp/foo
rm /tmp/foo
```

### How to Add a New Secret Profile

1. Create a directory for the new profile:
   ```bash
   mkdir -p secrets/profiles/<profile_name>/ssh
   ```
2. Encrypt the profile's environment variables:
   ```bash
   age -r age1r7hzm4zqsyu880e3f8yn97g7d6jqtxaeg8jjk2xpzqv2d9zgkelq00nmxn -o secrets/profiles/<profile_name>/local.zsh.age local.zsh
   ```
3. Commit the encrypted `.age` files (never commit the plaintext versions).
