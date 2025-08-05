{ config, hostCfg, ... }:
let
  gitPrompt = builtins.fetchurl {
    url =
      "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh";
    sha256 = "7ff718f4a06fd0a0be7edfef926abb41b1353c48c1515ad312d226965b74943a";
  };
  PROJECT_ROOT = hostCfg.root;
in {
  programs = {
    bash = {
      enable = true;
      profileExtra = ''
        # if running bash
        if [ -n "$BASH_VERSION" ]; then
            # include .bashrc if it exists
            if [ -f "$HOME/.bashrc" ]; then
          . "$HOME/.bashrc"
            fi
        fi

        # set PATH so it includes user's private bin if it exists
        if [ -d "$HOME/bin" ] ; then
            PATH="$HOME/bin:$PATH"
        fi

        # set PATH so it includes user's private bin if it exists
        if [ -d "$HOME/.local/bin" ] ; then
            PATH="$HOME/.local/bin:$PATH"
        fi
      '';
      initExtra = ''
        # some more ls aliases  
        alias ll='ls -alF'      
        alias la='ls -A'        
        alias l='ls -CF'        
        alias sudonix='sudo env PATH=$PATH'
        alias k='kubectl'
        alias rm="trash-put"

        # export BASH_COMPLETION_USER_DIR=$HOME/.nix-profile/share/bash-completion.d/

        # Eternal bash history.
        # ---------------------
        # Undocumented feature which sets the size to "unlimited".
        # http://stackoverflow.com/questions/9457233/unlimited-bash-history
        export HISTFILESIZE=
        export HISTSIZE=
        # export HISTTIMEFORMAT="[%F %T] "
        # Change the file location because certain bash sessions truncate .bash_history file upon close.
        # http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
        export HISTFILE=~/.bash_eternal_history
        # Force prompt to write history after every command.
        # PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
        PROMPT_COMMAND="history -a '$HISTFILE'; $PROMPT_COMMAND"

        export PATH="$PATH:${PROJECT_ROOT}/scripts"
        # source ${PROJECT_ROOT}/scripts/nokia.prox.sh

        # Source custom configuration
        if [ -f "$HOME/.bashrc.zs00lt" ]; then
          . "${PROJECT_ROOT}/config-files/bashrc.zs00lt"
        fi

        # source <(kubectl completion bash)
        # source <(helm completion bash)
        # source <(rclone completion bash)

        source ${gitPrompt}
        eval "$(starship init bash)"
      '';
    };
  };

}
