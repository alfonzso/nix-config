{ config, NixSecrets, pkgs, lib, ... }:
let
  _hostCfg = config.hostCfg;
  _lib = _hostCfg._lib;
in {

  options = {
    hostCfg = {
      _lib = lib.mkOption {
        type = lib.types.attrs;
        default = import ./helpers.nix { inherit config; };
        description = "Helpers of nix-config";
      };
      genNetMan = lib.mkOption {
        type = lib.types.attrs;
        default = _: "Not implemented yet...";
        description = "Network Manager generator wrapper";
      };
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
      sambaUser = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "User of samba";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "zs00lt";
        description = "Hostname of the machine";
      };

      # network = {
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

  config.hostCfg.genNetMan = _lib.genNetManProfiles _hostCfg.network.wifiNames;

}
