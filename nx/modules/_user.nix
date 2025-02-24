{ 
  config,
  lib,
  ...
}:
let
  hostCfg = config.hostCfg ;
in
{
  users = {
    mutableUsers = true;
    users = {
      "${hostCfg.username}" = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.${hostCfg.username}.path;
        extraGroups = [ 
          "wheel" 
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgcJfi0dZotMWa8zQvxXduM76GmQfoPvMU5FjIFZCAa alfonzso@gmail.com"
        ];
      };
      root = {
        # isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.root.path;
      };
    };
  };
}
