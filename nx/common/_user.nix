{ config, lib, personal, ... }:
let
  hostCfg = config.hostCfg;
  # lel = builtins.trace "Value of myAttr: ${builtins.toJSON kek}" kek ;
  # hostCfg = builtins.trace "Value of myAttr: ${builtins.toJSON config.hostCfg}" config.hostCfg ;
  # hostCfg = builtins.trace config.hostCfg.domain config.hostCfg ;
  # personal = builtins.trace personal.domain personal ;
  # lll = builtins.trace personal.ssh personal ;
  # _ = builtins.trace personal.ssh personal ;
  # hostCfg = builtins.trace
  #   ( "HOSTCFG = " + toJSON hostCfg )
  #   config.hostCfg;

  _hashedPasswordFile = config.sops.secrets.${hostCfg.username}.path;
in {
  users = {
    mutableUsers = true;
    users = {
      "${hostCfg.username}" = {
        isNormalUser = true;
        hashedPasswordFile = builtins.trace _hashedPasswordFile _hashedPasswordFile ;
        extraGroups = [ "wheel" "nasusers" ];
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
      root = {
        hashedPasswordFile = config.sops.secrets.root.path;
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
    };
  };
}
