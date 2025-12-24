{ NixSecrets, pkgs, lib, ... }:
let
in {

  options = {
    hostCfg = {
      root = lib.mkOption {
        type = lib.types.path;
        default = ./.;
        description = "Global root path for shared resources";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "User of the machine";
      };
      nasUser = lib.mkOption {
        type = lib.types.str;
        default = "nasadmin";
        description = "User of samba/nfs";
      };
      nasGroup = lib.mkOption {
        type = lib.types.str;
        default = "nasuser";
        description = "Group of samba/nfs";
      };

      currentConfigName = lib.mkOption {
        type = lib.types.str;
        default = "zs00lt";
        description = "Name of current flake config";
      };

      machineHostName = lib.mkOption {
        type = lib.types.str;
        default = "zs00lt";
        description = "Hostname of the machine";
      };

      storage = lib.mkOption {
        type = lib.types.submodule {
          options = {
            disksUUID = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of pre-exsisted disk uuid";
            };
          };
        };
      };

      network = lib.mkOption {
        type = lib.types.submodule {
          options = {
            wifiNames = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of wifi host";
            };
          };
        };
      };
    };
  };

}
