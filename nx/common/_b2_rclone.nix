{ pkgs, config, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";

  hostCfg = config.hostCfg;
  b2_rclone_wrapper = (pkgs.writeScriptBin "b2rclone" ''

    export RCLONE_CONFIG=/home/zsolt/.config/rclone/b2.storage.conf
    # ${pkgs.rclone}/bin/rclone --config=/home/${hostCfg.username}/.config/rclone/b2.storage.conf "$@"
  '');
in {

  sops = {

    # age.keyFile = "/home/${hostCfg.username}/.config/sops/age/keys.txt";

    secrets = {
      "b2/storage-bucket/account" = { sopsFile = "${sopsFolder}/b2.yaml"; };
      "b2/storage-bucket/key" = { sopsFile = "${sopsFolder}/b2.yaml"; };
      "restic/password" = {
        sopsFile = "${sopsFolder}/b2.yaml";
        owner = hostCfg.username;
      };
    };

    templates = {
      # "restic-open" = {
      #   content = ''
      #     export RESTIC_REPOSITORY=rclone:b2-storage:cnwco-storage/restic
      #     export RCLONE_CONFIG=/home/zsolt/.config/rclone/b2.storage.conf
      #     export RESTIC_PASSWORD=${config.sops.placeholder."restic/password"}
      #   '';
      # };
      "b2.storage.rclone.conf" = {
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

  };

  systemd.tmpfiles.rules = [
    "d /mnt/b2-storage 0755 ${hostCfg.username} users -"
    "d /mnt/restic 0755 ${hostCfg.username} users -"
    "d /home/${hostCfg.username}/.config/rclone 0755 ${hostCfg.username} users -"
  ];

  home-manager = {
    users.${hostCfg.username} = {

      programs = {
        bash = {
          enable = true;
          initExtra = ''
            if [ -f ${b2_rclone_wrapper}/bin/b2_rclone_wrapper ]; then
              . ${b2_rclone_wrapper}/bin/b2_rclone_wrapper
            fi
          '';
        };
      };

      home.packages = [

        b2_rclone_wrapper

        # (pkgs.writeShellScriptBin "b2rclone" ''
        #   ${pkgs.rclone}/bin/rclone --config=/home/${hostCfg.username}/.config/rclone/b2.storage.conf "$@"
        # '')

        # (pkgs.writeScriptBin "restic-open" config.sops.templates."restic-open".content)
        (pkgs.writeScriptBin "restic-open" ''
          export RESTIC_REPOSITORY=rclone:b2-storage:cnwco-storage/restic
          export RCLONE_CONFIG=/home/zsolt/.config/rclone/b2.storage.conf
          export RESTIC_PASSWORD=$(cat ${
            config.sops.secrets."restic/password".path
          })
        '')
      ];

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
