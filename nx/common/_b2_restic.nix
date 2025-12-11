{ pkgs, config, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";

  hostCfg = config.hostCfg;

  b2_rclone_wrapper = (pkgs.writeScriptBin "__b2rclone_o" ''
    function b2-rclone-open() {
      export RCLONE_CONFIG=/home/${hostCfg.username}/.config/rclone/b2.storage.conf
    }
  '');

  restic_wrapper = (pkgs.writeScriptBin "__restic_o" ''
    function restic-open(){
      export RESTIC_REPOSITORY=rclone:b2-storage:cnwco-storage/restic
      export RCLONE_CONFIG=/home/${hostCfg.username}/.config/rclone/b2.storage.conf
      export RESTIC_PASSWORD=$(cat ${
        config.sops.secrets."restic/password".path
      })
    }
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
      "b2.storage.rclone.conf" = {
        content = ''
          [b2-storage]
          type = b2
          account = ${config.sops.placeholder."b2/storage-bucket/account"}
          key = ${config.sops.placeholder."b2/storage-bucket/key"}
        '';
        owner = hostCfg.username;
        path = "/home/${hostCfg.username}/.config/rclone/b2.storage.conf";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/b2-storage                          0755 ${hostCfg.username} users -"
    "d /mnt/restic                              0755 ${hostCfg.username} users -"
    # first create .config if not exists
    # then create rclone folder, this way .config folder has correct user rights
    "d /home/${hostCfg.username}/.config        0755 ${hostCfg.username} users -"
    "d /home/${hostCfg.username}/.config/rclone 0755 ${hostCfg.username} users -"
  ];

  home-manager = {
    users.${hostCfg.username} = {

      programs = {
        bash = {
          enable = true;
          initExtra = ''
            if [ -f ${b2_rclone_wrapper}/bin/__b2rclone_o ]; then
              . ${b2_rclone_wrapper}/bin/__b2rclone_o
            fi
            if [ -f ${restic_wrapper}/bin/__restic_o ]; then
              . ${restic_wrapper}/bin/__restic_o
            fi
          '';
        };
      };

      home.packages = [ b2_rclone_wrapper restic_wrapper ];

      # mkdir -p /home/${hostCfg.username}/.config/rclone || true
      # cat ${
      #   config.sops.templates."b2.storage.rclone.conf".path
      # } > /home/${hostCfg.username}/.config/rclone/b2.storage.conf";
      systemd.user.services = let
        b2Script = pkgs.writeShellScript "b2" ''
          set -ex
          # mkdir -p /home/${hostCfg.username}/.config/rclone || true
          cat ${
            config.sops.templates."b2.storage.rclone.conf".path
          } > /home/${hostCfg.username}/.config/rclone/b2.storage.conf

        '';
      in {
        # b2-rclone-config = {
        #   Unit = {
        #     Description = "Copy rclone config to home/.config/rclone";
        #     After = [ "network-online.target" ];
        #   };
        #   Service = {
        #     Type = "oneshot";
        #     ExecStart = "${b2Script}";
        #   };
        #   Install.WantedBy = [ "default.target" ];
        # };
        b2-mounts = {
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
  };
}
