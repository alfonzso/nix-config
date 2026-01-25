{ pkgs, config, NixSecrets, ProjectRoot, ... }:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;

  b2RcloneWrapper = (pkgs.writeScriptBin "__b2rclone_o" ''
    function b2-rclone-open() {
      export RCLONE_CONFIG=/home/$USER/.config/rclone/b2.storage.conf
    }
  '');

  resticWrapper = (pkgs.writeScriptBin "__restic_o" ''
    function restic-open(){
      export RESTIC_REPOSITORY=rclone:b2-storage:cnwco-storage/restic
      export RCLONE_CONFIG=/home/$USER/.config/rclone/b2.storage.conf
      export RESTIC_PASSWORD=$(cat ${
        config.sops.secrets."restic/password".path
      })
    }
  '');

  resticBackupWrapper = let
    resticExcludeFiles = ProjectRoot + "/config-files/restic-exclude-files.txt";
  in (pkgs.writeScriptBin "__restic_backup" ''
    function restic-backup(){
      local backup_it_now=''${1:-"--dry-run --verbose=2"}
      restic backup /home/$USER --exclude-file ${resticExcludeFiles} $backup_it_now
      if [[ -z "$1" ]]; then
        echo "!!!! DRY RUN WAS ENABLED WITH RESTIC !!!!!"
        echo "!!!! DRY RUN WAS ENABLED WITH RESTIC !!!!!"
        echo "!!!! DRY RUN WAS ENABLED WITH RESTIC !!!!!"
        echo "To disable dry-run please run: restic-backup 'doit' or give any parameter"
      fi
    }
  '');

in {

  sops = {

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
            _run_sh_completion() {
              local cur="''${COMP_WORDS[COMP_CWORD]}"
              local options=""

              [[ ! -f .run.cmpl ]] && return 1

              # First argument: your custom completions
              if [[ $COMP_CWORD -eq 1 ]]; then
                local options=$(bash .run.cmpl)
                COMPREPLY=( $(compgen -W "$options" -- "$cur") )
                return
              fi
            }

            complete -o default -F _run_sh_completion run.sh
            complete -o default -F _run_sh_completion ./run.sh

            if [ -f ${b2RcloneWrapper}/bin/__b2rclone_o ]; then
              . ${b2RcloneWrapper}/bin/__b2rclone_o
            fi
            if [ -f ${resticWrapper}/bin/__restic_o ]; then
              . ${resticWrapper}/bin/__restic_o
            fi
            if [ -f ${resticBackupWrapper}/bin/__restic_backup ]; then
              . ${resticBackupWrapper}/bin/__restic_backup
            fi
          '';
        };
      };

      home.packages = [
        pkgs.restic
        pkgs.rclone
        b2RcloneWrapper
        resticWrapper
        resticBackupWrapper
      ];

    };
  };
}
