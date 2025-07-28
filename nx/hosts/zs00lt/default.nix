{ inputs, config, pkgs, lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  hostCfg = config.hostCfg;
in {
  system.stateVersion = "25.05";

  imports = lib.flatten [
    ./hm
    ./hardware-configuration.nix

    ./modules/config.nix
    ./modules/sops.nix

    "${_common}/_default_config.nix"

    "${_common}/desktop/gnome.gdm.nix"
    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"

  ];

}
