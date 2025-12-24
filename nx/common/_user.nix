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
        extraGroups = [ "wheel" ]
          ++ (if config.virtualisation.podman.enable then [ "podman" ] else [])
          ++ (if config.services.samba.enable then [ "nasusers" ] else [] )
          ++ (if config.services.printing.enable then [ "scanner" "lp" ] else [] )
          ;
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
      root = {
        hashedPasswordFile = config.sops.secrets.root.path;
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
    };
  };
}
