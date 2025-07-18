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
    };
  };
}
