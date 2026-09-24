#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
# Examples:
#   scripts/_run_nx_any.sh zs00lt
#   SSH_HOST=root@zs00lt-c0r3 scripts/_run_nx_any.sh c0r3
#   PHASES=install SSH_HOST=root@zs00lt-c0r3 scripts/_run_nx_any.sh c0r3
#   SSH_HOST=root@zs00lt-c0r3 scripts/_run_nx_any.sh c0r3 -build-host -target-host
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

_extras="kexec,disko,install"
extras="--phases ${PHASES:-$_extras}"
nixos_anywhere_args=()

for arg in "${@:2}"; do
	case "$arg" in
	-build-host | --build-host)
		nixos_anywhere_args+=(--build-on-remote)
		;;
	-target-host | --target-host)
		nixos_anywhere_args+=(--target-host "$_ssh_host")
		;;
	*)
		nixos_anywhere_args+=("$arg")
		;;
	esac
done

keys_src_persist="/persist/sops/age/keys.txt"

root=$(mktemp -d)
trap 'command rm -rf -- "$root"' EXIT
keys_target="$root/persist/sops/age/keys.txt"
install -d -m 0700 "$(dirname "$keys_target")"
install -m 0600 /dev/null "$keys_target"

if [[ -f "$keys_src_persist" && -s "$keys_src_persist" && ! -L "$keys_src_persist" && -r "$keys_src_persist" ]]; then
	cat "$keys_src_persist" >"$keys_target"
elif command -v sudo >/dev/null \
	&& sudo test -f "$keys_src_persist" \
	&& sudo test -s "$keys_src_persist" \
	&& sudo test ! -L "$keys_src_persist"; then
	sudo cat "$keys_src_persist" >"$keys_target"
else
	echo "Cannot read canonical sops age key: $keys_src_persist"
	exit 1
fi

nix run github:numtide/nixos-anywhere -- \
	--flake .#$target ${extras} --extra-files $root "${nixos_anywhere_args[@]}" \
	$_ssh_host
