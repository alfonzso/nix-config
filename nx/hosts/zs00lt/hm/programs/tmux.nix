{
config,
pkgs,
hostCfg,
...
}:
# let
#   hostCfg = config.hostCfg ;
# in
{
    programs.tmux = {
      enable = true;
      extraConfig = ''
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
      '';
    };

}
