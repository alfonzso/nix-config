{
  config,
  lib,
  ...
}:
let

  wifiList = [ "house" "house5" ];
  # wifiList = [ ];
  interface = "wlan0";
  _lib = config.hostCfg._lib ;

in
{

  networking = {
    enableIPv6  = false;
    hostName = config.hostCfg.hostname;
    wireless = {
      enable = ! _lib.isEmpty wifiList;
      networks = _lib.genNetworks wifiList ; 
      interfaces = [ interface ];
    };
  };

}
