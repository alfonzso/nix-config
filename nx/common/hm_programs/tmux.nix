{ config, pkgs, hostCfg, ... }:
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

      # bind-key q last-window
      # bind q last-window
      bind-key -T prefix e switch-client -T last_window
      bind-key -T last_window e last-window
      # List of plugins
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -sg escape-time 50
      set-window-option -g mode-keys vi
      # press <prefix>‑T to toggle between C‑b and C‑a
      bind-key T run-shell "~/.tmux/toggle-prefix.sh"
      set-option -g default-shell "/bin/bash"
      set -g default-terminal "screen-256color"
      new -n WindowName bash --login
      # Other examples:
      # set -g @plugin 'github_username/plugin_name'
      # set -g @plugin 'git@github.com/user/plugin'
      # set -g @plugin 'git@bitbucket.com/user/plugin'
      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run '~/.tmux/plugins/tpm/tpm'

    '';
  };

}
