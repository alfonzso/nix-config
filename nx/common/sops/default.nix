{ config, lib, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;

in {

  # mount /home dir before sops
  fileSystems."/home".neededForBoot = true;

  sops.age.keyFile = "/persist/sops/age/keys.txt";

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.currentConfigName}.yaml";

    secrets = lib.mkMerge [{
      root = { neededForUsers = true; };
      ${hostCfg.username} = { neededForUsers = true; };
    }];

  };

}
