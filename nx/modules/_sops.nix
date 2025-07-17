{
  inputs,
  config,
  lib,
  NixSecrets,
  ...
}:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;
in
  # builtins.trace (builtins.toJSON sopsFolder)
{

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.hostname}.yaml";
    validateSopsFiles = false;
    
    age.keyFile = "/tmp/keys.txt";

    secrets = {

      root = {
      	neededForUsers = true;
      };

      ${hostCfg.username} = {
      	neededForUsers = true;
      };

      # TODO: needed auto default secret from sops ?
      # "wifi/house"  = {} ; 
      # "wifi/house5" = {} ; 
    };

  };

}
