{ lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _desktop = ProjectRoot + "/nx/desktop";
  _activations = _common + "/activations";
in {
  imports = lib.flatten [
    ./hm
    "${_common}/hm"

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/deploy_ssh_files.nix"

    "${_common}/sops"
    "${_common}/sops/ssh.nix"
    "${_common}/sops/wifi.nix"

    "${_common}/nix/common.nix"
    "${_common}/nix/config_nix.nix"
    "${_common}/nix/env_sys_pack.nix"

    "${_common}/networking/networking.nix"
    "${_common}/networking/ssh.nix"

    "${_common}/_virtualisation.nix"
    "${_common}/_user.nix"

    "${_common}/_b2_restic.nix"

  ];

  system.stateVersion = "25.05";

}
