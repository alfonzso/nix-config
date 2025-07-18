{
  inputs,
  config,
  lib,
  ...
}:
let
  hostCfg = config.hostCfg;
in
{

  sops = {
    secrets = {

      samba_user_pwd = {
        owner = "${hostCfg.username}" ;
      };

      # TODO: needed auto default secret from sops ?
      # "wifi/house"  = {} ; 
      # "wifi/house5" = {} ; 
    };
  };
}
