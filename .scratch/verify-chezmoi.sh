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

# Symlink the repository to ~/.local/share/chezmoi as a real deployment would
ln -sf "${REPO_DIR}" "${TEST_HOME}/.local/share/chezmoi"

# Verify that running chezmoi source-path naturally matches the repository root
actual_source=$(HOME="${TEST_HOME}" "${CHEZMOI_BIN}" source-path)
resolved_source=$(realpath "${actual_source}")
resolved_repo=$(realpath "${REPO_DIR}")

if [ "${resolved_source}" != "${resolved_repo}" ]; then
  echo "FAIL: chezmoi source-path (${resolved_source}) does not match expected (${resolved_repo})"
  exit 1
fi
echo "PASS: chezmoi source-path matches repository root"

# 2. Run chezmoi init with mock inputs
echo "Running chezmoi init..."
HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${REPO_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" init \
  --promptString "What is your git author name?=Test Author" \
  --promptString "What is your git author email?=test@example.com" \
  --promptBool "Is this a headless machine (no GUI)?=false"

# 3. Run chezmoi apply to deploy files to the test HOME
echo "Running chezmoi apply..."
# Prepend mock sudo bin to PATH so Chezmoi scripts use it
PATH="${TEST_HOME}/.local/bin:${PATH}" HOME="${TEST_HOME}" "${CHEZMOI_BIN}" --source "${REPO_DIR}" --config "${TEST_HOME}/chezmoi.toml" --destination "${TEST_HOME}" apply --force

# 4. Assertions on deployed configuration files
assert_exists() {
  if [ ! -e "$1" ]; then
    echo "FAIL: expected file/folder $1 does not exist"
    exit 1
  fi
}

assert_executable() {
  if [ ! -x "$1" ]; then
    echo "FAIL: expected file $1 to be executable"
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

# Ticket 3 Assertions: Linux Configurations
assert_exists "${TEST_HOME}/.config/btop"
assert_exists "${TEST_HOME}/.config/chrome-flags.conf"
assert_exists "${TEST_HOME}/.config/fcitx5"
assert_exists "${TEST_HOME}/.config/hypr"
assert_exists "${TEST_HOME}/.config/kitty"
assert_exists "${TEST_HOME}/.config/swaync"
assert_exists "${TEST_HOME}/.config/walker"
assert_exists "${TEST_HOME}/.config/waybar"

# Ticket 3 Assertions: Executable scripts in ~/.local/bin/
assert_exists "${TEST_HOME}/.local/bin/pm.sh"
assert_executable "${TEST_HOME}/.local/bin/pm.sh"
assert_exists "${TEST_HOME}/.local/bin/walker-bw"
assert_executable "${TEST_HOME}/.local/bin/walker-bw"
assert_exists "${TEST_HOME}/.local/bin/systemupdate.sh"
assert_executable "${TEST_HOME}/.local/bin/systemupdate.sh"

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

# Ticket 3 Assertions: Plymouth theme copy via run-onchange
assert_exists "${TEST_HOME}/usr/share/plymouth/themes/achron/achron.plymouth"

echo "PASS: All configurations and installers migrated and verified successfully!"
exit 0
