{ config, lib, ... }:
let

  # # wifiList = [ "house" "house5" ];
  # wifiList = [ ];
  # interface = "wlan0";
  # _lib = config.hostCfg._lib;

  # machineHostName = config.hostCfg.machineHostName + "Nix";
  # wifiList = config.hostCfg.network.wifiNames ;


  # houseWifiProfile = wifiList:
  #   ''WIFI_${lib.strings.toUpper name}="${config.sops.placeholder."wifi/${name}"}"''
  # ) config.hostCfg.network.wifiNames );
  houseWifiProfile = builtins.listToAttrs (map (name: {
      inherit name;
      value = {
        connection = {
          id = "${name}";
          type = "wifi";
        };
        wifi = {
          ssid = "${name}";
          mode = "infrastructure";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$WIFI_${lib.strings.toUpper name}";
        };
      };
    }) config.hostCfg.network.wifiNames );

in {

  networking = {
    enableIPv6 = false;
    hostName = config.hostCfg.machineHostName ;
    networkmanager = {
      enable = true ;
      ensureProfiles = {
        environmentFiles = [ config.sops.templates."wifi.env".path ];
        profiles = lib.mkMerge [
          {}
          houseWifiProfile
        ];

      };
    };
  };

}
