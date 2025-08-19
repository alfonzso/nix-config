# sudo nixos-rebuild switch --flake .#zs00lt $@
# nixos-rebuild --flake .#nas --impure --target-host root@nasNix switch

# extras="--phases kexec,disko,install"
extras="--phases kexec,disko,install"
# extras="--phases kexec,install"

nix run \
  github:numtide/nixos-anywhere -- \
  --flake .#zs00lt \
  ${extras} \
  --disko-mode mount \
  --extra-files $(pwd)/nx/extra-files  \
  root@zs00lt.lan

# nix run github:numtide/nixos-anywhere -- \
#   --flake .#nas ${extras} --extra-files $(pwd)/nx/extra-files  \
#   admin@nix-iso
