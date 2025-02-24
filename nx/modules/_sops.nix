{
  inputs,
  config,
  lib,
  ...
}:
let
  sopsFolder = (builtins.toString inputs.nix-secrets) + "/sops";
  hostCfg = config.hostCfg;
in
{

  # imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # options._SOPS.dsf = lib.mkOption {
  #   # type = lib.types.str;
  #   type = lib.types.path;
  #   # default = ./nx/secrets/secrets.yaml;
  #   # default = nx/secrets/secrets.yaml;
  #   default = "nx/secrets/secrets.yaml" ;
  #   description = "DefaultSopsFile.";
  # };

  # sops-nix.nixosModules.sops

  # config.sops = {
  sops = {
    # defaultSopsFile = ./secrets/secrets.yaml;

    defaultSopsFile = "${sopsFolder}/${config.hostCfg.hostname}.yaml";
    validateSopsFiles = false;

    # defaultSopsFile = config._SOPS.dsf ; 
    
    age.keyFile = "/tmp/keys.txt";

    # secrets = wifi.genSecrets wifiList // {
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
