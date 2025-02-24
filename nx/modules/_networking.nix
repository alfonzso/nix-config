{
  config,
  lib,
  ...
}:
let

  # wifiList = [ "house" "house5" ];
  wifiList = [ ];
  interface = "wlan0";
  _lib = config.hostCfg._lib ;

  HostName = config.hostCfg.hostname + "Nix" ;
in
{

  networking = {
    enableIPv6  = false;
    hostName = HostName ;
    wireless = {
      enable = ! _lib.isEmpty wifiList;
      networks = _lib.genNetworks wifiList ; 
      interfaces = [ interface ];
    };
  };

}
