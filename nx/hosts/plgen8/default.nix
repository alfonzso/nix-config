{ config, lib, ProjectRoot, ... }:
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
    # "${_activations}/manage_ssh.nix"
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
    ./modules/k8s.nix
    ./modules/sops.nix

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/manage_ssh.nix"

    "${_common}/fileshare/user.nix"
    "${_common}/fileshare/samba.nix"
    {
      services.samba.settings = lib.mkForce {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        secure = {
          path = "/mnt/secure";
          browseable = "yes";
          writable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "${config.hostCfg.nasUser}";
          "write list" = "${config.hostCfg.nasUser}";
          "create mask" = "0755";
          "directory mask" = "0755";
        };
        fast = {
          path = "/mnt/fast";
          browseable = "yes";
          writable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = "${config.hostCfg.nasUser}";
          "write list" = "${config.hostCfg.nasUser}";
          "create mask" = "0755";
          "directory mask" = "0755";
        };
      };

      users.groups.zfs-storage = { gid = 990; };
      users.users.${config.hostCfg.nasUser}.extraGroups = [ "zfs-storage" ];
      systemd.tmpfiles.rules = [
        "d /mnt/fast   2775 root zfs-storage - -"
        "d /mnt/secure 2775 root zfs-storage - -"

        # # More explicit ACLs (Default ACLs (Access Control Lists))
        # # with this setup zfs-storage 775 permission will intherit to all files/folders
        # "a+ /mnt/fast    - - - - default:user::rwx,default:group:zfs-storage:rwx,default:other::rx"
        # "a+ /mnt/secure  - - - - default:user::rwx,default:group:zfs-storage:rwx,default:other::rx"
      ];
    }

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
