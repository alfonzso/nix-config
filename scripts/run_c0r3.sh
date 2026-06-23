#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
ws="$(realpath "$DIR/../")"
target="c0r3"
phase="${1:-install}"
ssh_host="${SSH_HOST:-root@192.168.1.100}"

usage() {
	cat <<EOF
Usage:
  bash scripts/run_c0r3.sh disko
  bash scripts/run_c0r3.sh install

Environment:
  SSH_HOST=$ssh_host

Steps:
  disko   Wipe only the configured 1TB disk and create /nix + /games.
  install Install c0r3 with nixos-anywhere using the already prepared /mnt layout.

Expected install mounts:
  /mnt        New NixOS ext4 root partition
  /mnt/boot   New NixOS-dedicated EFI partition, not the Windows EFI partition
  /mnt/nix    300G ext4 partition on the 1TB disk
  /mnt/games  Remaining ext4 partition on the 1TB disk
EOF
}

require_no_placeholder() {
	local description=$1
	local pattern=$2
	shift 2

	if grep -R "$pattern" "$@" >/dev/null; then
		echo "Refusing to run: replace $description first."
		grep -R -n "$pattern" "$@" || true
		exit 1
	fi
}

case "$phase" in
disko)
	require_no_placeholder \
		"the 1TB disk by-id placeholder in nx/hosts/c0r3/modules/disko.nix" \
		"CHANGE-ME-c0r3-1tb-disk" \
		"$ws/nx/hosts/c0r3/modules/disko.nix"

	echo "About to run disko for $target on $ssh_host."
	echo "This will wipe the configured 1TB disk and create /nix + /games."
	PHASES=disko SSH_HOST="$ssh_host" "$DIR/_run_nx_any.sh" "$target"
	;;

install)
	require_no_placeholder \
		"all c0r3 disk UUID placeholders" \
		"CHANGE-ME-c0r3" \
		"$ws/nx/hosts/c0r3/modules/disko.nix" \
		"$ws/nx/hosts/c0r3/hardware-configuration.nix"

	echo "About to install $target on $ssh_host."
	echo "Expected remote mounts: /mnt, /mnt/boot (NixOS EFI), /mnt/nix, /mnt/games."
	PHASES=install SSH_HOST="$ssh_host" "$DIR/_run_nx_any.sh" "$target"
	;;

-h | --help | help)
	usage
	;;

*)
	echo "Unknown phase: $phase"
	usage
	exit 1
	;;
esac
