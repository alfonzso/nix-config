{ ... }: {

  isEmpty = value:
    value == null || (builtins.isList value && value == [ ])
    || (builtins.isString value && value == "")
    || (builtins.isAttrs value && builtins.attrNames value == [ ]);

  # genNetManProfiles = wifiList:
  #   builtins.listToAttrs (map (name: {
  #     inherit name;
  #     # value = { psk = config.sops.secrets."wifi/${name}".path; };
  #     # environmentFiles = [ config.sops.secrets."wireless.env".path ];
  #
  #     value = {
  #       connection = {
  #         id = "${name}";
  #         type = "wifi";
  #       };
  #       wifi = {
  #         ssid = "${name}";
  #         mode = "infrastructure";
  #       };
  #       wifi-security = {
  #         key-mgmt = "wpa-psk";
  #         psk = config.sops.secrets."wifi/${name}".path;
  #         # psk = sops.secrets."wifi/${name}".path;
  #       };
  #     };
  #   }) wifiList);

  # genNetworks = wifiList:
  #   builtins.listToAttrs (map (name: {
  #     inherit name;
  #     value = { psk = config.sops.secrets."wifi/${name}".path; };
  #     # value = { psk = sops.secrets."wifi/${name}".path; };
  #   }) wifiList);
  #
  # genSecrets = wifiList: {
  #   wifi = builtins.listToAttrs (map (name: {
  #     inherit name;
  #     value = { };
  #   }) wifiList);
  # };

}
