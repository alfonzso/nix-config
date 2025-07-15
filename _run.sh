#!/usr/bin/env bash

extras="--phases kexec,disko,install"
extras=""
extras="--phases kexec,disko,install"

# nix run github:numtide/nixos-anywhere -- \
#   --flake .#zs00lt ${extras} --extra-files $(pwd)/nx/extra-files  \
#   nixiso

nix run github:numtide/nixos-anywhere -- \
  --flake .#nas ${extras} --extra-files $(pwd)/nx/extra-files  \
  admin@nix-iso

# kexec,disko,install
