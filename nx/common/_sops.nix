{ inputs, config, lib, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;
  # builtins.trace (builtins.toJSON sopsFolder)
in {

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.hostname}.yaml";
    # validateSopsFiles = true;

    age.keyFile = "/tmp/keys.txt";

    secrets = {

      root = { neededForUsers = true; };

      ${hostCfg.username} = { neededForUsers = true; };

      samba_user_pwd = { owner = "${hostCfg.username}"; };

      "samba/user/name" = { };
      "samba/user/password" = { };

      # TODO: needed auto default secret from sops ?
      # "wifi/house"  = {} ; 
      # "wifi/house5" = {} ; 
    };

  };

}
