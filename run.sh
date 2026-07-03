name=$1
shift
[[ -z "$name" ]] && {
	ls -la nx/hosts
	exit 1
}

if command -v nixos-rebuild >/dev/null 2>&1; then
	sudo nixos-rebuild --flake .#$name "$@"
else
	nix run nixpkgs#nixos-rebuild -- --flake .#$name "$@"
fi
