name=$1
shift
[[ -z "$name" ]] && { ls -la nx/hosts; exit 1; }
sudo nixos-rebuild --flake .#$name $@

