{ config, lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _activations = _common + "/activations";
in {
  imports = with config.hostCfg;
    lib.flatten [

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
            "valid users" = "${nasUser}";
            "write list" = "${nasUser}";
            "create mask" = "0664";
            "directory mask" = "0775";
          };
          fast = {
            path = "/mnt/fast";
            browseable = "yes";
            writable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = "${nasUser}";
            "write list" = "${nasUser}";
            "create mask" = "0664";
            "directory mask" = "0775";
          };
        };

        # environment.etc."profile.d/umask-storage-users.sh" = {
        environment.extraInit = ''
          case "$USER" in
            ${username}|${nasUser})
              umask 002
              ;;
          esac
        '';

        users.groups.zfs-storage = { gid = 990; };
        users.users.${username}.extraGroups = [ "zfs-storage" ];
        users.users.${nasUser}.extraGroups = [ "zfs-storage" ];
        systemd.tmpfiles.rules = [
          "d /mnt/fast   2775 root zfs-storage - -"
          "d /mnt/secure 2775 root zfs-storage - -"

          # # More explicit ACLs (Default ACLs (Access Control Lists))
          # # with this setup zfs-storage 775 permission will intherit to all files/folders
          # "a+ /mnt/fast    - - - - default:user::rwx,default:group:zfs-storage:rwx,default:other::rx"
          # "a+ /mnt/secure  - - - - default:user::rwx,default:group:zfs-storage:rwx,default:other::rx"
        ];
      }
    ];
}
