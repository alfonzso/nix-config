{
  inputs,
  config,
  lib,
  ...
}:
let
  sopsFolder = (builtins.toString inputs.nix-secrets) + "/sops";
  hostCfg = config.hostCfg;
  _lib = config.hostCfg._lib;
in
{

  sops = {

    defaultSopsFile = "${sopsFolder}/${config.hostCfg.hostname}.yaml";
    validateSopsFiles = false;
    
    age.keyFile = "/tmp/keys.txt";

    secrets = {

      root = {
      	neededForUsers = true;
      };

      ${hostCfg.username} = {
      	neededForUsers = true;
      };

      "wifi/house"  = {} ; 
      "wifi/house5" = {} ; 
    };

  };

}
