{ pkgs, config, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";

  hostCfg = config.hostCfg;
in {

  sops = {

    # age.keyFile = "/home/${hostCfg.username}/.config/sops/age/keys.txt";

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
      owner = hostCfg.username;
      # owner = config.users.users."${hostCfg.username}" ;
      path = "/home/${hostCfg.username}/.config/rclone/b2.storage.conf";
    };

  };

  systemd.tmpfiles.rules = [
    "d /mnt/b2-storage 0755 ${hostCfg.username} users -"
    "d /home/${hostCfg.username}/.config/rclone 0755 ${hostCfg.username} users -"
  ];

  home-manager = {
    users.${hostCfg.username} = {

      systemd.user.services.b2-mounts = {
        Unit = {
          Description =
            "Example programmatic mount configuration with nix and home-manager.";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "notify";
          ExecStart = ''
            ${pkgs.rclone}/bin/rclone --config=%h/.config/rclone/b2.storage.conf --vfs-cache-mode writes --ignore-checksum mount b2-storage: /mnt/b2-storage ;
          '';
          ExecStop = "/run/wrappers/bin/fusermount -u /mnt/b2-storage ";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };

}
