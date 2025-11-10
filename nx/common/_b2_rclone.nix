{ config, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";

  hostCfg = config.hostCfg;
in {

  sops = {

    age.keyFile = "/home/${hostCfg.username}/.config/sops/age/keys.txt";

    secrets = {
      "b2/storage-bucket/account" = { sopsFile = "${sopsFolder}/b2.yaml"; };
      "b2/storage-bucket/key" = { sopsFile = "${sopsFolder}/b2.yaml"; };
    };

    templates."b2.storage.rclone.conf" = {
      content = ''
        [b2-storage]
        type = b2
        account = ${config.sops.placeholder."b2/storage-bucket/account"}
        key = ${config.sops.placeholder."b2/storage-bucket/key"}
      '';
      path = "/home/${hostCfg.username}/.config/rclone/b2.storage.conf";
    };

  };
}
