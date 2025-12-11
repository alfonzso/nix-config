{ config, lib, ProjectRoot, ... }:
let
  nxLib = ProjectRoot + "/nx/lib";
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
  }) config.hostCfg.network.wifiNames);

in {

  sops = {
    secrets = lib.mkMerge [
      (import "${nxLib}/_sops_wifi.nix" {
        wifiNames = config.hostCfg.network.wifiNames;
      })
    ];
    templates."wifi.env".content = lib.concatStringsSep "\n" (map (name: ''
      WIFI_${lib.strings.toUpper name}="${
        config.sops.placeholder."wifi/${name}"
      }"
    '') config.hostCfg.network.wifiNames);
  };

  networking = {
    networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [ config.sops.templates."wifi.env".path ];
        profiles = lib.mkMerge [ { } houseWifiProfile ];
      };
    };
  };

}
