#!/usr/bin/env bash
#
# Chezmoi installation state validation script

set -euo pipefail

# Locate the repository root dynamically (supporting execution from any directory)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
CHEZMOI_BIN="${REPO_DIR}/bin/chezmoi"

if [ ! -f "${CHEZMOI_BIN}" ]; then
  echo "FAIL: chezmoi binary not found at ${CHEZMOI_BIN}"
  exit 1
fi

assert_not_exists() {
  if [ -e "$1" ]; then
    echo "FAIL: legacy file/folder $1 still exists"
    exit 1
  fi
}

echo "Verifying legacy configurations cleanup..."
assert_not_exists "${REPO_DIR}/config"
assert_not_exists "${REPO_DIR}/functions"
assert_not_exists "${REPO_DIR}/bin/bootstrap"
assert_not_exists "${REPO_DIR}/bin/decrypt"
assert_not_exists "${REPO_DIR}/bin/encrypt"

if [ ! -d "${REPO_DIR}/assets/plymouth" ]; then
  echo "FAIL: assets/plymouth folder not found"
  exit 1
fi


# Setup a clean test HOME directory to verify default resolution (non-tautological)
TEST_HOME="/tmp/dotfiles-test-home"
rm -rf "${TEST_HOME}"
mkdir -p "${TEST_HOME}/.local/bin"
mkdir -p "${TEST_HOME}/.local/share"

# Create a mock sudo executable to redirect system paths and avoid password prompts
MOCK_SUDO="${TEST_HOME}/.local/bin/sudo"
cat << 'EOF' > "${MOCK_SUDO}"
#!/usr/bin/env bash
# Mock sudo: simply execute command, redirecting /usr/share/plymouth/themes to test sandbox
args=()
for arg in "$@"; do
  if [[ "$arg" == "/usr/share/plymouth/themes"* ]]; then
    args+=("/tmp/dotfiles-test-home${arg}")
  else
    args+=("$arg")
  fi
done
exec "${args[@]}"
EOF
chmod +x "${MOCK_SUDO}"

# Create a mock plymouth-set-default-theme executable to prevent permission errors
MOCK_PLYMOUTH="${TEST_HOME}/.local/bin/plymouth-set-default-theme"
cat << 'EOF' > "${MOCK_PLYMOUTH}"
#!/usr/bin/env bash
echo "Mocked setting default plymouth theme to $1"
EOF
chmod +x "${MOCK_PLYMOUTH}"

# Setup the source directory by copying files from the repository (instead of symlinking)
SRC_DIR="${TEST_HOME}/.local/share/chezmoi"
rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"
# Copy tracked repository files to the source directory, excluding secrets/
rsync -a --exclude '.git' --exclude 'secrets' "${REPO_DIR}/" "${SRC_DIR}/"

# Copy our test fixture secrets to the source directory's secrets/ folder
cp -R "${REPO_DIR}/.scratch/fixtures/secrets" "${SRC_DIR}/secrets"

# Copy the custom profile scaffold from the real repository to the test source directory
mkdir -p "${SRC_DIR}/secrets/profiles"
cp -R "${REPO_DIR}/secrets/profiles/custom" "${SRC_DIR}/secrets/profiles/custom"

# Copy the test age private key to the test identity path
mkdir -p "${TEST_HOME}/.local/share/age"
cp "${REPO_DIR}/.scratch/fixtures/test-key.txt" "${TEST_HOME}/.local/share/age/default-key.txt"
chmod 600 "${TEST_HOME}/.local/share/age/default-key.txt"

# Verify that running chezmoi source-path matches the source directory
actual_source=$(HOME="${TEST_HOME}" "${CHEZMOI_BIN}" source-path)
resolved_source=$(realpath "${actual_source}")
resolved_repo=$(realpath "${SRC_DIR}")

if [ "${resolved_source}" != "${resolved_repo}" ]; then
  echo "FAIL: chezmoi source-path (${resolved_source}) does not match expected (${resolved_repo})"
  exit 1
fi
echo "PASS: chezmoi source-path matches source directory"

# Scenario A: Test apply with a known profile (test-profile)
echo "Running chezmoi init for test-profile..."
HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${SRC_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" init \
  --promptString "What is your git author name?=Test Author" \
  --promptString "What is your git author email?=test@example.com" \
  --promptBool "Is this a headless machine (no GUI)?=false" \
  --promptString "Enter machine profile name=test-profile"

echo "Running chezmoi apply for test-profile..."
PATH="${TEST_HOME}/.local/bin:${PATH}" HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${SRC_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" apply --force

# 4. Assertions on deployed configuration files
assert_exists() {
  if [ ! -e "$1" ]; then
    echo "FAIL: expected file/folder $1 does not exist"
    exit 1
  fi
}

assert_not_exists_in_home() {
  if [ -e "$1" ]; then
    echo "FAIL: file/folder should not exist in home: $1"
    exit 1
  fi
}

assert_executable() {
  if [ ! -x "$1" ]; then
    echo "FAIL: expected file $1 to be executable"
    exit 1
  fi
}

assert_file_mode() {
  local expected_mode="$1"
  local file="$2"
  if [ ! -e "$file" ]; then
    echo "FAIL: file does not exist for mode check: $file"
    exit 1
  fi
  local actual_mode
  actual_mode=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
  if [ "$actual_mode" != "$expected_mode" ]; then
    echo "FAIL: $file has mode $actual_mode, expected $expected_mode"
    exit 1
  fi
}

echo "Running asset assertions..."
assert_exists "${TEST_HOME}/.gitconfig"
assert_exists "${TEST_HOME}/.gitignore"
assert_exists "${TEST_HOME}/.gitattributes"
assert_exists "${TEST_HOME}/.tmux.conf"
assert_exists "${TEST_HOME}/.zshrc"
assert_exists "${TEST_HOME}/.config/zsh/common.zsh"
assert_exists "${TEST_HOME}/.config/zsh/alias.zsh"
assert_exists "${TEST_HOME}/.config/fastfetch/config.jsonc"
assert_exists "${TEST_HOME}/.config/fastfetch/logo/wolf.txt"

# Platform Specific Assertions
if [ "$(uname)" = "Darwin" ]; then
  echo "Running macOS asset assertions..."
  assert_exists "${TEST_HOME}/.Brewfile"
  assert_exists "${TEST_HOME}/.amethyst.yml"
  assert_exists "${TEST_HOME}/Library/Preferences/com.lujjjh.LinearMouse.plist"
  assert_exists "${TEST_HOME}/Library/Preferences/com.googlecode.iterm2.plist"
  assert_exists "${TEST_HOME}/Library/Application Support/Alfred/exact_Alfred.alfredpreferences"
  assert_exists "${TEST_HOME}/.config/karabiner/karabiner.json"
  assert_exists "${TEST_HOME}/.config/iterm2/themes"
  assert_exists "${TEST_HOME}/.config/raycast"
else
  echo "Running Linux asset assertions..."
  assert_exists "${TEST_HOME}/.config/btop"
  assert_exists "${TEST_HOME}/.config/chrome-flags.conf"
  assert_exists "${TEST_HOME}/.config/fcitx5"
  assert_exists "${TEST_HOME}/.config/hypr"
  assert_exists "${TEST_HOME}/.config/kitty"
  assert_exists "${TEST_HOME}/.config/swaync"
  assert_exists "${TEST_HOME}/.config/walker"
  assert_exists "${TEST_HOME}/.config/waybar"

  # Config script executable assertions
  assert_executable "${TEST_HOME}/.config/hypr/scripts/workspace-switch.sh"
  assert_executable "${TEST_HOME}/.config/waybar/scripts/brightnesscontrol.sh"
  assert_executable "${TEST_HOME}/.config/waybar/scripts/volumecontrol.sh"
  assert_executable "${TEST_HOME}/.config/waybar/scripts/cpuinfo.sh"
  assert_executable "${TEST_HOME}/.config/waybar/scripts/gpuinfo.sh"
  assert_executable "${TEST_HOME}/.config/waybar/scripts/amdgpu.py"

  # Ticket 3 Assertions: Executable scripts in ~/.local/bin/
  assert_exists "${TEST_HOME}/.local/bin/pm.sh"
  assert_executable "${TEST_HOME}/.local/bin/pm.sh"
  assert_exists "${TEST_HOME}/.local/bin/walker-bw"
  assert_executable "${TEST_HOME}/.local/bin/walker-bw"
  assert_exists "${TEST_HOME}/.local/bin/systemupdate.sh"
  assert_executable "${TEST_HOME}/.local/bin/systemupdate.sh"

  # Ticket 3 Assertions: Plymouth theme copy via run-onchange
  assert_exists "${TEST_HOME}/usr/share/plymouth/themes/achron/achron.plymouth"
fi

# 5. Assertions on generated content
if ! grep -q "name = \"Test Author\"" "${TEST_HOME}/.gitconfig"; then
  echo "FAIL: .gitconfig does not contain the generated user name"
  exit 1
fi
if ! grep -q "email = \"test@example.com\"" "${TEST_HOME}/.gitconfig"; then
  echo "FAIL: .gitconfig does not contain the generated user email"
  exit 1
fi
if ! grep -q "ZINIT_CUSTOM_HOME=\"\${HOME}/.config/zsh\"" "${TEST_HOME}/.zshrc"; then
  echo "FAIL: .zshrc does not point ZINIT_CUSTOM_HOME to ~/.config/zsh"
  exit 1
fi

# 6. Assertions on lifecycle script executions
assert_exists "${TEST_HOME}/.local/share/zinit/zinit.git/zinit.zsh"
assert_exists "${TEST_HOME}/.tmux/plugins/tpm/tpm"
assert_exists "${TEST_HOME}/.config/nvim/lua/config/lazy.lua"

# Ticket 1 Assertions: No raw .age ciphertext files in $HOME (excluding the chezmoi source directory)
echo "Running secret infrastructure assertions..."
while IFS= read -r -d '' age_file; do
  assert_not_exists_in_home "${age_file}"
done < <(find "${TEST_HOME}" -path "${TEST_HOME}/.local/share/chezmoi" -prune -o -name '*.age' -print0 2>/dev/null | grep -zv "^\.")

# Issue #17 Assertions: Secret deployment script (Scenario A: Known Profile)
echo "Running secret deployment assertions (test-profile)..."
# Base SSH key deployed
assert_exists "${TEST_HOME}/.ssh/id_ed25519"
assert_file_mode 600 "${TEST_HOME}/.ssh/id_ed25519"
# Check base SSH key content matches the decrypted dummy content
if ! grep -q "dummy_base_ssh_key_content" "${TEST_HOME}/.ssh/id_ed25519"; then
  echo "FAIL: id_ed25519 content does not match dummy fixture"
  exit 1
fi

# Profile specific SSH key deployed
assert_exists "${TEST_HOME}/.ssh/test_key"
assert_file_mode 600 "${TEST_HOME}/.ssh/test_key"
if ! grep -q "dummy_profile_ssh_key_content" "${TEST_HOME}/.ssh/test_key"; then
  echo "FAIL: test_key content does not match dummy fixture"
  exit 1
fi

# SSH directory mode
assert_file_mode 700 "${TEST_HOME}/.ssh"

# Environment variables deployed
assert_exists "${TEST_HOME}/.config/zsh/local.zsh"
assert_file_mode 600 "${TEST_HOME}/.config/zsh/local.zsh"
if ! grep -q "TEST_ENV_VAR=\"dummy_value\"" "${TEST_HOME}/.config/zsh/local.zsh"; then
  echo "FAIL: local.zsh content does not match dummy fixture"
  exit 1
fi


# Scenario B: Custom Profile Fallback
echo "Running Scenario B: Custom profile fallback..."
# Clear home directory files except .local to ensure clean apply (deletes chezmoi.toml to force re-prompting)
find "${TEST_HOME}" -mindepth 1 -maxdepth 1 ! -name ".local" -exec rm -rf {} +

# Re-init for custom profile fallback (using an unknown profile name)
echo "Running chezmoi init for unknown-profile..."
HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${SRC_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" init \
  --promptString "What is your git author name?=Test Author" \
  --promptString "What is your git author email?=test@example.com" \
  --promptBool "Is this a headless machine (no GUI)?=false" \
  --promptString "Enter machine profile name=unknown-profile"

echo "Running chezmoi apply for custom..."
PATH="${TEST_HOME}/.local/bin:${PATH}" HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${SRC_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" apply --force

echo "Running Scenario B assertions..."
# Custom profile: local.zsh scaffold must be present
assert_exists "${TEST_HOME}/.config/zsh/local.zsh"
assert_file_mode 600 "${TEST_HOME}/.config/zsh/local.zsh"
if ! grep -q "template for your Secret Profile" "${TEST_HOME}/.config/zsh/local.zsh"; then
  echo "FAIL: local.zsh does not contain scaffold comment"
  exit 1
fi

# test_key should NOT be present under custom profile
assert_not_exists_in_home "${TEST_HOME}/.ssh/test_key"


echo "PASS: All configurations and installers migrated and verified successfully!"
exit 0
