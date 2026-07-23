#!/usr/bin/env sh
#
# Bootstrap dotfiles on a fresh machine (installs git, chezmoi, age, and applies config)

set -eu

echo "Bootstrapping dotfiles..."

# 1. Detect OS
OS="$(uname -s)"
case "${OS}" in
  Darwin)
    echo "Detected macOS."
    if ! command -v brew >/dev/null 2>&1; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Load brew in current shell context
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
    echo "Installing base utilities (git, chezmoi, age)..."
    brew install git chezmoi age
    ;;
  Linux)
    echo "Detected Linux."
    if [ -f /etc/arch-release ]; then
      echo "Arch Linux detected. Installing git, chezmoi, age..."
      sudo pacman -S --needed --noconfirm git chezmoi age
    elif [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
      echo "Debian/Ubuntu detected. Installing git, chezmoi, age..."
      sudo apt-get update
      sudo apt-get install -y git chezmoi age
    elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
      echo "Fedora/RHEL detected. Installing git, chezmoi, age..."
      sudo dnf install -y git chezmoi age
    elif [ -f /etc/alpine-release ]; then
      echo "Alpine Linux detected. Installing git, chezmoi, age..."
      sudo apk add git chezmoi age
    else
      echo "Unknown Linux distribution. Please ensure git, chezmoi, and age are installed manually."
    fi
    ;;
  *)
    echo "Unsupported OS: ${OS}. Please set up git, chezmoi, and age manually."
    exit 1
    ;;
esac

# 2. Check if git, chezmoi, age are available
for cmd in git chezmoi age; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: ${cmd} is not installed or not in PATH."
    exit 1
  fi
done

# 3. Apply chezmoi configurations
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "${REPO_DIR}/.git" ] && [ -f "${REPO_DIR}/.chezmoiignore" ]; then
  echo "Running from local repository at ${REPO_DIR}."
  chezmoi init --apply --source "${REPO_DIR}"
else
  echo "Running remotely. Initializing chezmoi from icyleaf/dotfiles repository..."
  chezmoi init --apply icyleaf
fi

echo "Bootstrapping complete!"
