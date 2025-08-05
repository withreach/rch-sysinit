#!/bin/bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
sysinit_path="$HOME/sysinit"
packages="curl file git gpg"
repository=https://github.com/withreach/rch-sysinit.git

trap cleanup ERR EXIT

cleanup() {
  # Clean up temporary files
  rm -f "$script_dir/mise_install.sh"

  if command -v deactivate >/dev/null; then
    deactivate
  fi
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
"dnf")
  sudo sh -c "dnf update; dnf install -y $packages"
  ;;
"yum")
  sudo sh -c "yum update; yum install -y $packages"
  ;;
*)
  echo "Unsupported package manager"
  exit 1
  ;;
esac

# Install mise
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt >"$script_dir/mise_install.sh"
sh "$script_dir/mise_install.sh"

# Add mise to PATH and activate it
export PATH="$HOME/.local/bin:$PATH"
echo "eval \"\$($HOME/.local/bin/mise activate bash)\"" >>~/.bashrc
eval "$("$HOME"/.local/bin/mise activate bash)"

# Install uv via mise
mise use --global uv
uv venv --clear "$HOME/.venv/sysinit"
source "$HOME/.venv/sysinit/bin/activate"

if [ -d "${sysinit_path}" ] && [ -d "${sysinit_path}/.git" ]; then
  git -C "${sysinit_path}" pull
else
  git clone -b main --single-branch $repository "$sysinit_path"
fi

cd "${sysinit_path}" || exit 1
mise trust -a
uv pip install -r requirements.txt

ansible-playbook playbook.yml -K

# hosts=(admin checkout reports stash redirect)
# target_ip=127.0.0.1
# for host in "${hosts[@]}"; do
#   if ! grep -qE "^\s*${target_ip}\s+${host}(\s|$)" /etc/hosts; then
#     echo -e "${target_ip}\t${host}" | sudo tee -a /etc/hosts >/dev/null
#   fi
# done
