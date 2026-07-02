#!/usr/bin/env bash
set -euo pipefail

# Run nixos-anywhere against the installer-ISO VM booted by
# scripts/test-alpine-anywhere-iso.sh.
#
# The Alpine installer ISO is NOT NixOS, so the kexec phase is always required.
# This wraps run_test_c0r3.sh (which handles the sops age-key copy, phases and
# the ssh reachability check) with defaults pointed at the local ISO VM.
#
# Typical flow:
#   Terminal 1: scripts/test-alpine-anywhere-iso.sh
#   Terminal 2: scripts/run-alpine-anywhere-iso.sh          # kexec,disko,install
#               scripts/run-alpine-anywhere-iso.sh disko    # kexec,disko only

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
WS="$(realpath "$DIR/..")"

PHASE="${1:-install}"

# ISO-VM defaults (overridable from the environment).
export SSH_HOST="${SSH_HOST:-root@127.0.0.1}"
export SSH_PORT="${SSH_PORT:-2222}"
export SSH_KEY="${SSH_KEY:-$WS/var/vm/c0r3/id_ed25519}"

usage() {
  cat <<EOF
Usage:
  $0 [disko|install]

Runs nixos-anywhere (--flake .#test-c0r3) against the installer-ISO VM.
Because the ISO is Alpine (not NixOS), the kexec phase is always included:
  disko    -> kexec,disko
  install  -> kexec,disko,install   (default)

Environment (current defaults):
  SSH_HOST=$SSH_HOST
  SSH_PORT=$SSH_PORT
  SSH_KEY=$SSH_KEY
  PHASES=<override nixos-anywhere phases>
EOF
}

case "$PHASE" in
-h | --help | help)
  usage
  exit 0
  ;;
esac

exec "$DIR/run_test_c0r3.sh" "$PHASE"
