{ config, lib, pkgs, ... }:
let
  _hostCfg = config.hostCfg;
  _common = _hostCfg.root + "/nx/common";
in {
  imports = lib.flatten [
    ./hm
    ./hardware-configuration.nix
    ./_global_host_config.nix

    ./modules/config.nix
    # ./modules/mergerfs_4_samba.nix
    # ./modules/samba.nix
    # ./modules/nfs.nix
    # ./modules/mergerfs_4_nfs.nix
    ./modules/sops.nix

    # ./modules/mounts.nix

    "${_common}/_nix_conf.nix"
    "${_common}/_common_and_sys_env.nix"
    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"

  ];

  config = { environment.systemPackages = with pkgs; [ zfs ]; };

  system.stateVersion = "25.11";

}
