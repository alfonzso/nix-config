{ config, personal, ... }:
let
  hostCfg = config.hostCfg;
  _hashedPasswordFile = config.sops.secrets.${hostCfg.username}.path;
in {
  users = {
    mutableUsers = true;
    users = {
      "${hostCfg.username}" = {
        isNormalUser = true;
        hashedPasswordFile =
          builtins.trace _hashedPasswordFile _hashedPasswordFile;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
      root = {
        hashedPasswordFile = config.sops.secrets.root.path;
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
    };
  };
}
