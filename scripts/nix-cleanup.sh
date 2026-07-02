#!/usr/bin/env bash
set -euo pipefail

KEEP_GENERATIONS="${KEEP_GENERATIONS:-5}"

if [[ ! "$KEEP_GENERATIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "KEEP_GENERATIONS must be a positive integer, got: $KEEP_GENERATIONS" >&2
  exit 1
fi

echo "Keeping the newest $KEEP_GENERATIONS NixOS system generations."
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations "+$KEEP_GENERATIONS"

if [[ -e "$HOME/.nix-profile" ]]; then
  echo "Keeping the newest $KEEP_GENERATIONS user profile generations for $USER."
  nix-env --delete-generations "+$KEEP_GENERATIONS" || true
fi

if command -v home-manager >/dev/null 2>&1; then
  echo "Keeping recent Home Manager generations."
  home-manager expire-generations "-30 days" || true
fi

echo "Collecting unreachable Nix store paths."
sudo nix-store --gc

echo "Refreshing bootloader entries."
sudo /run/current-system/bin/switch-to-configuration boot

echo "Done."
