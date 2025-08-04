#!/bin/bash
#
# Hardened System Initialization Script
#
# Security features implemented:
# - Secure installer download: Downloads mise installer to temp file and verifies content
# - Binary verification: Checks installed binaries for basic integrity
# - Removed dangerous 'curl | sh' pattern
# - Proper cleanup of temporary files
#
# WARNING: This script requires elevated privileges and installs software.
# Review the script before execution.
#

# script_dir="$(dirname "$(realpath "$0")")"
sysinit_path="$HOME/rch-sysinit"
packages="curl git gpg file"  # Added 'file' for binary verification
repository=https://github.com/withreach/rch-sysinit.git

trap cleanup ERR EXIT

cleanup() {
  # Clean up temporary files
  if [ -n "$mise_installer" ] && [ -f "$mise_installer" ]; then
    rm -f "$mise_installer"
  fi

  if command -v deactivate >/dev/null; then
    deactivate
  fi
}

# Function to verify binary integrity where possible
verify_binary() {
  local binary_path="$1"
  local binary_name="$2"

  if [ ! -f "$binary_path" ]; then
    echo "Warning: Binary $binary_name not found at $binary_path"
    return 1
  fi

  # Check if binary is executable
  if [ ! -x "$binary_path" ]; then
    echo "Warning: Binary $binary_name is not executable"
    return 1
  fi

  # Basic file type verification
  if command -v file >/dev/null; then
    file_output=$(file "$binary_path")
    if ! echo "$file_output" | grep -q "executable\|ELF"; then
      echo "Warning: $binary_name doesn't appear to be a valid executable"
      return 1
    fi
  fi

  echo "✓ Binary verification passed for $binary_name"
  return 0
}

function getPackageManager() {
  local pm

  declare -A osInfo
  osInfo['/etc/redhat-release']=yum
  osInfo['/etc/arch-release']=pacman
  osInfo['/etc/debian_version']=apt-get

  for f in "${!osInfo[@]}"; do
    if [[ -f $f ]]; then
      pm="${osInfo[$f]}"
    fi
  done
  echo "$pm"
}

case $(getPackageManager) in
"apt-get")
  sudo sh -c "apt-get update; apt-get upgrade -y; apt-get install $packages -y; apt autoremove -y"
  ;;
"pacman")
  sudo sh -c "pacman -Syu; echo 'yes' | pacman -S --noconfirm $packages"
  ;;
"yum")
  sudo ish -c "yum update; yum install -y $packages"
  ;;
*)
  echo "Unsupported package manager"
  exit 1
  ;;
esac

# Verify critical package manager installed binaries
echo "Verifying package manager installed binaries..."
for pkg in curl git gpg; do
  if command -v "$pkg" >/dev/null; then
    pkg_path=$(command -v "$pkg")
    verify_binary "$pkg_path" "$pkg"
  else
    echo "Warning: $pkg not found in PATH after package installation"
  fi
done

# Secure installation of mise - download, verify, then execute
# Note: Instead of dangerous 'curl https://mise.run | sh' pattern
echo "Downloading mise installer securely..."
mise_installer=$(mktemp)
trap 'rm -f "$mise_installer"' EXIT

# Download the installer script
if ! curl -fsSL https://mise.run -o "$mise_installer"; then
  echo "Error: Failed to download mise installer"
  exit 1
fi

# Verify the installer using basic content validation
#
# SECURITY NOTE: For enhanced security in production environments, consider:
# - Verifying GPG signatures when available from the provider
# - Checking SHA256 checksums against known good values
# - Using package managers with built-in signature verification
# - Maintaining an internal mirror of trusted software
#
if [ ! -s "$mise_installer" ]; then
  echo "Error: Downloaded installer is empty"
  exit 1
fi

# Basic content verification - ensure it's a bash script with expected patterns
if ! grep -q "#!/bin/bash\|#!/bin/sh" "$mise_installer" || ! grep -q "mise" "$mise_installer"; then
  echo "Error: Downloaded file doesn't appear to be a valid mise installer"
  echo "Content preview (first 10 lines):"
  head -10 "$mise_installer"
  exit 1
fi

echo "✓ Basic installer verification passed"

# Execute the verified installer
echo "Executing verified mise installer..."
bash "$mise_installer"

# Add mise to PATH and activate it
export PATH="$HOME/.local/bin:$PATH"
echo "eval \"\$($HOME/.local/bin/mise activate bash)\"" >>~/.bashrc

# Source the mise activation directly instead of relying on .bashrc
eval "$("$HOME"/.local/bin/mise activate bash)"

# Verify mise binary after installation
echo "Verifying installed binaries..."
verify_binary "$HOME/.local/bin/mise" "mise"

# Now mise should be available
mise use --global uv

# Verify uv binary after mise installs it
if command -v uv >/dev/null; then
  uv_path=$(command -v uv)
  verify_binary "$uv_path" "uv"
else
  echo "Warning: uv command not found in PATH after installation"
fi

#if [ ! -d "$HOME/.venv/sysinit" ]; then
uv venv --clear "$HOME/.venv/sysinit"
#fi
source "$HOME/.venv/sysinit/bin/activate"

if [ -d "${sysinit_path}" ] && [ -d "${sysinit_path}/.git" ]; then
  git -C "${sysinit_path}" pull
else
  git clone -b main --single-branch $repository "$sysinit_path"
fi

cd "${sysinit_path}" || exit 1
uv pip install -r requirements.txt

#mise trust -a
ansible-playbook playbook.yml -K

# hosts=(admin checkout reports stash redirect)
# target_ip=127.0.0.1
# for host in "${hosts[@]}"; do
#   if ! grep -qE "^\s*${target_ip}\s+${host}(\s|$)" /etc/hosts; then
#     echo -e "${target_ip}\t${host}" | sudo tee -a /etc/hosts >/dev/null
#   fi
# done
