# { config, lib, HostName, ProjectRoot, NixSecrets, ... }:
{ config, lib, ProjectRoot, NixSecrets, ... }:
let personal = import NixSecrets + "/personal";
in {

  hostCfg.root = ProjectRoot;
  hostCfg.username = "nxadmin";
  # hostCfg.sambaUser = "smbAdmin";
  hostCfg.NASUser = "nasadmin";
  # hostCfg.machineHostName = machineHostName;

  hostCfg.storage.disksUUID = [
    "d8fd4b40-38c2-4ef3-b8e3-d383f9a1470e"
    "883e96f9-df17-4a9f-b233-7c75330c6e4d"
    "36691558-2c47-4492-b479-1a43d295e4e3"
  ];

}
