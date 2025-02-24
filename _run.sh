nix run github:numtide/nixos-anywhere -- \
  --flake .#zs00ltNix --phases kexec,disko,install --extra-files $(pwd)/nx/extra-files  \
  nixiso

# kexec,disko,install
