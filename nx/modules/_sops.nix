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
    # validateSopsFiles = false;
    # validateSopsFiles = true;
    
    age.keyFile = "/tmp/keys.txt";

    secrets = {

      root = {
      	neededForUsers = true;
      };

      ${hostCfg.username} = {
      	neededForUsers = true;
      };

      # "samba/user" = {};
      # "samba/user/name" = {
      #   key     = "samba.user.name";      # YAML path `samba.user`
      #   # format  = "json";            # or `"yaml"` if you want a YAML blob
      # };

      samba_user_pwd = {
        owner = "${hostCfg.username}" ;
      };

      "samba/user/name" = {};
      "samba/user/password" = {};

      # TODO: needed auto default secret from sops ?
      # "wifi/house"  = {} ; 
      # "wifi/house5" = {} ; 
    };

  };

}
