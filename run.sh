name=$1
[[ -z "$name" ]] && { ls -la nx/hosts; exit 1; }
shift
sudo nixos-rebuild --flake .#$name "$@"
