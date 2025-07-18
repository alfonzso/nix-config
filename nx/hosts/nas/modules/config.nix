{ config, lib, HostName, ProjectRoot, NixSecrets, ... }:
let personal = import NixSecrets + "/nix/personal.nix";
in {

  hostCfg.root = ProjectRoot;
  hostCfg.username = "nxadmin";
  hostCfg.sambaUser = "smbAdmin";
  hostCfg.hostname = HostName;

}
