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
in {
  users = {
    mutableUsers = true;
    users = {
      "${hostCfg.username}" = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.${hostCfg.username}.path;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = personal.ssh.public;
        # openssh.authorizedKeys.keys = lll.ssh.public  ;
        # [
        #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgcJfi0dZotMWa8zQvxXduM76GmQfoPvMU5FjIFZCAa alfonzso@gmail.com"
        # ];
      };
      root = {
        # isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.root.path;
        openssh.authorizedKeys.keys = personal.ssh.public;
      };
    };
  };
}
