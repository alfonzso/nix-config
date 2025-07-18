{ config, lib, pkgs, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  # sambaPassPath = config.sops.secrets.samba_user_pwd.path;
in {
  home-manager = {
    extraSpecialArgs = { hostCfg = config.hostCfg; };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {
      imports = [
        ./programs/git.nix
        ./programs/bash.nix
        ./programs/tmux.nix
        ./programs/vim.nix
        ./packages.nix
      ];
      home = {

        activation.createCustomDir = lib.mkAfter ''
          mkdir -p ${vimTMP} || true
          chmod u+rw ${vimTMP}
        '';
        activation.cloneGitRepo = lib.mkAfter ''
          export PATH=${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH
          if [ ! -d "$HOME/.config/nvim/.git" ]; then
            git clone git@github.com:alfonzso/nvim.git $HOME/.config/nvim
          fi
        '';

        username =
          hostCfg.username; # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = "25.05";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

  # With nixOS and hm, it wont be intalled,
  # use instead: nixos-rebuild switch --flake .#asdf
  # programs.home-manager.enable = true;

}
