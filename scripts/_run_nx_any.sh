#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
# ws=$DIR/../
ws=$(realpath $DIR/../)

target=$1

[[ -z "$target" ]] && {
  ls -la $ws/nx/hosts/
  exit 1
}
[[ ! -e "$ws/nx/hosts/$target" ]] && {
  echo "$target hosts at ./nx/hosts/ not exists.."
  exit 1
}

_ssh_host="admin@nix-$target-iso"
# _ssh_host="admin@nix-plgen8-iso"
_uptime_test=$(ssh $_ssh_host -- "uptime")
[[ -z "$_uptime_test" ]] && {
  echo "cannot access the host: $_ssh_host"
  exit 1
}

# extras="--phases kexec,disko"
extras="--phases kexec,disko,install"

keys_src="/home/${USER}/.config/sops/age/keys.txt"
root=$(mktemp -d)
keys_target="$root/persist/sops/age/"

rsync -avz --mkpath $keys_src $keys_target

nix run github:numtide/nixos-anywhere -- \
  --flake .#$target ${extras} --extra-files $root \
  $_ssh_host

echo "rm -r $root"
