{ lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _activations = _common + "/activations";
in {
  imports = lib.flatten [
    # ./hm
    # "${_common}/hm"
    #
    # ./hardware-configuration.nix
    # ./_global_host_config.nix
    # ./modules/disko.nix
    #
    # # ./modules/config.nix
    # # ./modules/mergerfs_4_samba.nix
    # # ./modules/samba.nix
    # # ./modules/nfs.nix
    # # ./modules/mergerfs_4_nfs.nix
    # # ./modules/mounts.nix
    #
    # "${_common}/_ssh.nix"
    # "${_activations}/deploy_ssh_files.nix"
    # "${_common}/_sops/ssh.nix"
    #
    # ./modules/sops.nix
    # "${_common}/_sops"
    #
    # "${_common}/_nix_conf.nix"
    # "${_common}/_common_and_sys_env.nix"
    # "${_common}/_networking.nix"
    # "${_common}/_user.nix"

    ./hm
    "${_common}/hm"

    ./modules/disko.nix

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/deploy_ssh_files.nix"

    "${_common}/sops"
    "${_common}/sops/ssh.nix"

    "${_common}/nix/common.nix"
    "${_common}/nix/config_nix.nix"
    "${_common}/nix/env_sys_pack.nix"

    "${_common}/networking"
    "${_common}/networking/ssh.nix"

    "${_common}/_virtualisation.nix"
    "${_common}/_user.nix"

    "${_common}/_b2_restic.nix"
  ];

  system.stateVersion = "25.11";

}
