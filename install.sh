#!/bin/bash

script_dir="$(dirname "$(realpath "$0")")"
sysinit_path="$HOME/rch-sysinit"
packages="curl git gpg"
repository=https://github.com/withreach/rch-sysinit.git

trap cleanup ERR EXIT

cleanup() {
  if command -v deactivate &>/dev/null; then
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
"yum")
  sudo ish -c "yum update; yum install -y $packages"
  ;;
*)
  echo "Unsupported package manager"
  exit 1
  ;;
esac

curl https://mise.run | sh

# Add mise to PATH and activate it
export PATH="$HOME/.local/bin:$PATH"
echo "eval \"\$($HOME/.local/bin/mise activate bash)\"" >>~/.bashrc

# Source the mise activation directly instead of relying on .bashrc
eval "$($HOME/.local/bin/mise activate bash)"

# Now mise should be available
mise use --global uv

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
