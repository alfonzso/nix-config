name=$1
shift
[[ -z "$name" ]] && { ls -la hm/hosts; exit 1; }
sudo nixos-rebuild --flake .#$name $@

