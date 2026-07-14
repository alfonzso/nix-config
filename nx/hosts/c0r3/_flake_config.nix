# Host-specific flake input override template.
#
# c0r3 currently uses the global flake inputs from ../../../flake.nix. If this
# host needs a different nixpkgs/home-manager/sops-nix version in the future,
# uncomment the relevant attributes below and point them at the desired inputs.

{ ... }:
{ }

# Example:
#
# { inputs, ... }:
# {
#   nixpkgs = inputs.nixpkgs_unstable;
#   home-manager = inputs.home-manager_unstable;
#   sops-nix = inputs.sops_nix_unstable;
# }
