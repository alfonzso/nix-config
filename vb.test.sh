extras="--phases kexec,disko,install"
# extras="--phases kexec,install"
# extras="--phases kexec,install"

nix run github:numtide/nixos-anywhere -- \
  --flake .#zs00lt \
  ${extras} \
  --extra-files $(pwd)/nx/extra-files/ \
  root@nix-iso

# nixos-rebuild --flake .#zs00lt --impure --target-host root@zs00lt switch
# nixos-rebuild --flake .#zs00lt  --target-host root@zs00ltNix switch
