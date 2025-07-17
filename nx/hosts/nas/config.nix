{
  config,
  lib,
  HostName,
  ProjectRoot,
  ...
}:
let
  personal = import config.nixSecrets + "/nix/personal.nix";
in
{

  hostCfg.root = ProjectRoot ;
  hostCfg.username = "nxadmin" ;
  hostCfg.hostname = HostName ;

  # config.hostCfg = lib.deepRecMerge config.hostCfg personal;
  # hostCfg.network.wifiNames = [
  #   "house"
  #   "house5"
  # ];

}
