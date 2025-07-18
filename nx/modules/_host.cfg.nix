# {
#   config,
#   lib,
#   HostName,
#   ProjectRoot,
#   ...
# }:
# let
#   personal = import config.nixSecrets + "/nix/personal.nix";
# in

{
 config,
 NixSecrets,
 pkgs,
 lib,
 ...
}:
let
  # personal = import (NixSecrets + "/nix/personal.nix") ;
  # sops = config.sops ;
  # personal   = import "${NixSecrets}/nix/personal.nix" { inherit lib; };
  # personal   = import "${NixSecrets}/nix/personal.nix" ;
  _hostCfg = config.hostCfg ;
  _lib = _hostCfg._lib ;
in
{

  options = {
    hostCfg = {
      _lib = lib.mkOption {
        type = lib.types.attrs;
        default = import ./helpers.nix { inherit config; } ;
        # default = import ./helpers.nix {inherit sops ; } ; #  { inherit config; } ;
        description = "Helpers of nix-config";
      };
      genNetMan = lib.mkOption {
        type = lib.types.attrs;
        default = _: "Not implemented yet..." ;
        description = "Network Manager generator wrapper";
      };
      root = lib.mkOption {
        type = lib.types.path;
        default = ./. ;
        description = "Global root path for shared resources";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin" ;
        description = "User of the machine";
      };
      sambaUser = lib.mkOption {
        type = lib.types.str;
        default = "admin" ;
        description = "User of samba";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "zs00lt" ;
        description = "Hostname of the machine";
      };

      # network = {
      network = lib.mkOption {
        type = lib.types.submodule {
          options = {
            wifiNames = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "List of wifi host";
            };
          };
        };
      };
    } ; #  // (personal {});
  };

  config.hostCfg.genNetMan = _lib.genNetManProfiles _hostCfg.network.wifiNames ;
  # config.hostCfg = lib.deepRecMerge config.hostCfg personal;

}
