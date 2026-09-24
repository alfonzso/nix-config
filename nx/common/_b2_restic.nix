{ config, ... }:
let
  hostCfg = config.hostCfg;
in
{
  # restic and rclone come from home-manager modules/b2.rclone.nix.
  # These directories have to exist before that module writes the rclone config.
  systemd.tmpfiles.rules = [
    "d /mnt/b2-storage                          0755 ${hostCfg.username} users -"
    "d /mnt/restic                              0755 ${hostCfg.username} users -"
    # first create .config if not exists
    # then create rclone folder, this way .config folder has correct user rights
    "d /home/${hostCfg.username}/.config        0755 ${hostCfg.username} users -"
    "d /home/${hostCfg.username}/.config/rclone 0755 ${hostCfg.username} users -"
  ];

  home-manager.users.${hostCfg.username}.programs.bash = {
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
    '';
  };
}
