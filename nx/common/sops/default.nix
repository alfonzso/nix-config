{ config, lib, NixSecrets, pkgs, ... }:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;
  ageKeyFile = "/persist/sops/age/keys.txt";

in {
  system.activationScripts.lockSopsAgeKey.text = ''
    if [ -f ${ageKeyFile} ]; then
      ${pkgs.coreutils}/bin/chown root:root ${ageKeyFile}
      ${pkgs.coreutils}/bin/chmod 0600 ${ageKeyFile}
    fi
  '';

  sops.age.keyFile = ageKeyFile;

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.currentConfigName}.yaml";

    secrets = lib.mkMerge [{
      root = { neededForUsers = true; };
      ${hostCfg.username} = { neededForUsers = true; };
    }];

  };

}
