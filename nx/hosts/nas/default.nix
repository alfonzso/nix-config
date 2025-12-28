{ config, lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _desktop = ProjectRoot + "/nx/desktop";
  _activations = _common + "/activations";
in {

  users.users.${config.hostCfg.username} = { extraGroups = [ "${config.hostCfg.nasGroup}" ]; };

  users.groups."${config.hostCfg.nasGroup}" = { };
  users.users.${config.hostCfg.nasUser} = {
    isNormalUser = true;
    group = "${config.hostCfg.nasGroup}";
    extraGroups = [ "${config.hostCfg.nasGroup}" ];
  };

  imports = lib.flatten [
    ./hm
    "${_common}/hm"

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/manage_ssh.nix"

    "${_common}/sops"
    "${_common}/sops/ssh.nix"
    "${_common}/sops/wifi.nix"

    "${_common}/fileshare/mergerfs_4_samba.nix"
    "${_common}/fileshare/samba.nix"
    # ./modules/mergerfs_4_samba.nix
    # ./modules/samba.nix
    # ./modules/nfs.nix
    # ./modules/mergerfs_4_nfs.nix

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
