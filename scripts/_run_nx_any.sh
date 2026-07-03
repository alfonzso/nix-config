#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
# Examples:
#   scripts/_run_nx_any.sh zs00lt
#   SSH_HOST=root@zs00lt-c0r3 scripts/_run_nx_any.sh c0r3
#   PHASES=install SSH_HOST=root@zs00lt-c0r3 scripts/_run_nx_any.sh c0r3
#
# SSH_HOST defaults to admin@nix-<target>-iso.
# PHASES defaults to kexec,disko,install, except c0r3 defaults to install.
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

__ssh_host="admin@nix-$target-iso"
_ssh_host=${SSH_HOST:-$__ssh_host}
# _ssh_host="admin@nix-plgen8-iso"
_uptime_test=$(ssh $_ssh_host -- "uptime")
[[ -z "$_uptime_test" ]] && {
	echo "cannot access the host: $_ssh_host"
	exit 1
}

if [[ -z "${PHASES:-}" && "$target" == "c0r3" ]]; then
	_extras="install"
else
	_extras="kexec,disko,install"
fi
extras="--phases ${PHASES:-$_extras}"

keys_src_home="/home/${USER}/.config/sops/age/keys.txt"
keys_src_persists="/persists/sops/age/keys.txt"

if [[ -f "$keys_src_home" ]]; then
	keys_src="$keys_src_home"
elif [[ -f "$keys_src_persists" ]]; then
	keys_src="$keys_src_persists"
else
	echo "Cannot find sops age key."
	echo "Checked:"
	echo "  $keys_src_home"
	echo "  $keys_src_persists"
	exit 1
fi

root=$(mktemp -d)
keys_target="$root/persist/sops/age/"

if ! rsync -avz --mkpath "$keys_src" "$keys_target"; then
	echo "Failed to copy sops age key from $keys_src to $keys_target"
	exit 1
fi

nix run github:numtide/nixos-anywhere -- \
	--flake .#$target ${extras} --extra-files $root \
	$_ssh_host

echo "rm -r $root"
