#!/usr/bin/env bash
# Test verification script for refactored Linux dotfiles structure

set -eo pipefail

export TEST_HOME="/tmp/dotfiles-test-home"
rm -rf "$TEST_HOME"
mkdir -p "$TEST_HOME/.local/bin"

export HOME="$TEST_HOME"

# Mock sudo and plymouth tools
sudo() {
  if [ "$1" = "cp" ]; then
    local args=()
    for arg in "$@"; do
      if [[ "$arg" == "/usr/share/plymouth"* ]]; then
        local mocked_path="${TEST_HOME}${arg}"
        mkdir -p "$(dirname "$mocked_path")"
        args+=("$mocked_path")
      else
        args+=("$arg")
      fi
    done
    command cp "${args[@]:1}"
  elif [ "$1" = "mkdir" ]; then
    local args=()
    for arg in "$@"; do
      if [[ "$arg" == "/usr/share/plymouth"* ]]; then
        local mocked_path="${TEST_HOME}${arg}"
        mkdir -p "$mocked_path"
        args+=("$mocked_path")
      else
        args+=("$arg")
      fi
    done
    command mkdir "${args[@]:1}"
  elif [ "$1" = "plymouth-set-default-theme" ]; then
    echo "Mocked set theme to $2"
  else
    command "$@"
  fi
}
export -f sudo

plymouth-set-default-theme() {
  echo "mock-theme"
}
export -f plymouth-set-default-theme

# We mock hostname to return achron for plymouth testing
hostname() {
  echo "achron"
}
export -f hostname

echo "Running installers in sandbox HOME: $HOME..."

for mod in system walker waybar plymouth; do
  if [ -f "config/linux/${mod}/install.sh" ]; then
    bash "config/linux/${mod}/install.sh"
  fi
done

echo "Verifying installation results..."
errors=0

assert_symlink() {
  local link="$1"
  local target_suffix="$2"
  if [ ! -L "$link" ]; then
    echo "FAIL: $link is not a symbolic link"
    errors=$((errors + 1))
    return
  fi
  local target
  target=$(readlink -f "$link")
  if [[ "$target" != *"$target_suffix" ]]; then
    echo "FAIL: $link points to $target, expected suffix: $target_suffix"
    errors=$((errors + 1))
  else
    echo "PASS: $link points to $target"
  fi
}

assert_file_exists() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FAIL: File $file does not exist"
    errors=$((errors + 1))
  else
    echo "PASS: File $file exists"
  fi
}

# 1. Verify pm.sh (system)
assert_symlink "$HOME/.local/bin/pm.sh" "config/linux/system/bin/pm.sh"

# 2. Verify walker-bw, walker-clipboard, walker-wallpaper
assert_symlink "$HOME/.local/bin/walker-bw" "config/linux/walker/bin/walker-bw"
assert_symlink "$HOME/.local/bin/walker-clipboard" "config/linux/walker/bin/walker-clipboard"
assert_symlink "$HOME/.local/bin/walker-wallpaper" "config/linux/walker/bin/walker-wallpaper"

# 3. Verify systemupdate.sh (waybar)
assert_symlink "$HOME/.local/bin/systemupdate.sh" "config/linux/waybar/scripts/systemupdate.sh"

# 4. Verify plymouth themes
assert_file_exists "$HOME/usr/share/plymouth/themes/achron/achron.plymouth"

if [ "$errors" -ne 0 ]; then
  echo "Verification FAILED with $errors errors."
  exit 1
else
  echo "Verification PASSED!"
  exit 0
fi
