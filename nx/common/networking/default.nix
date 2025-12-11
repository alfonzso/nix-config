{ config, ... }: {
  networking = {
    enableIPv6 = false;
    hostName = config.hostCfg.machineHostName;
    networkmanager = { enable = true; };
  };
}
