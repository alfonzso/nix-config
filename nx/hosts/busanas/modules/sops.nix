{ config, ... }:
{
  sops.secrets.samba_user_pwd = {
    owner = config.hostCfg.username;
  };
}
