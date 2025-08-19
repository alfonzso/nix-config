{ config, lib, ... }:
let
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
