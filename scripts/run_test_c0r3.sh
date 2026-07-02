#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
WS="$(realpath "$DIR/..")"
TARGET="test-c0r3"
PHASE="${1:-install}"
SSH_HOST="${SSH_HOST:-root@127.0.0.1}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_KEY="${SSH_KEY:-$WS/var/vm/c0r3/id_ed25519}"
KEXEC_EXTRA_FLAGS="${KEXEC_EXTRA_FLAGS:---kexec-syscall-auto}"

usage() {
  cat <<EOF
Usage:
  $0 disko
  $0 install

Environment:
  SSH_HOST=$SSH_HOST
  SSH_PORT=$SSH_PORT
  SSH_KEY=$SSH_KEY
  KEXEC_EXTRA_FLAGS=$KEXEC_EXTRA_FLAGS
  PHASES=<override nixos-anywhere phases>

Examples:
  SSH_HOST=root@127.0.0.1 SSH_PORT=2222 $0 disko
  SSH_HOST=root@127.0.0.1 SSH_PORT=2222 $0 install
EOF
}

find_sops_key() {
  local candidates=(
    "/home/${USER}/.config/sops/age/keys.txt"
    "/persist/sops/age/keys.txt"
    "/persists/sops/age/keys.txt"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  echo "Cannot find sops age key." >&2
  echo "Checked:" >&2
  printf '  %s\n' "${candidates[@]}" >&2
  exit 1
}

case "$PHASE" in
disko)
  phases="${PHASES:-kexec,disko}"
  ;;
install)
  phases="${PHASES:-kexec,disko,install}"
  ;;
-h | --help | help)
  usage
  exit 0
  ;;
*)
  echo "Unknown phase: $PHASE" >&2
  usage >&2
  exit 1
  ;;
esac

if [[ ! -f "$SSH_KEY" ]]; then
  echo "Missing VM SSH private key: $SSH_KEY" >&2
  echo "Start the VM once with scripts/test-c0r3-vm.sh to create it." >&2
  exit 1
fi

if ! ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_HOST" -- "uptime" >/dev/null; then
  echo "Cannot access the test VM: $SSH_HOST on SSH port $SSH_PORT" >&2
  exit 1
fi

keys_src="$(find_sops_key)"
extra_files="$(mktemp -d)"
trap 'rm -rf "$extra_files"' EXIT

keys_target="$extra_files/persist/sops/age/"
rsync -avz --mkpath "$keys_src" "$keys_target"

cd "$WS"

nix run github:numtide/nixos-anywhere -- \
  --flake ".#$TARGET" \
  --phases "$phases" \
  --kexec-extra-flags "$KEXEC_EXTRA_FLAGS" \
  -i "$SSH_KEY" \
  --ssh-option "Port=$SSH_PORT" \
  --extra-files "$extra_files" \
  "$SSH_HOST"
