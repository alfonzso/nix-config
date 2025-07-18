{
# inputs,
config, lib, pkgs,
# hostCfg,
... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
in {
  # inherit hostCfg ;
  imports = [
    # ./programs/git.nix
    # ./programs/bash.nix
    # ./programs/tmux.nix
    # ./programs/vim.nix
    # ./packages.nix
  ];

  home-manager = {
    extraSpecialArgs = {
      # inherit pkgs inputs;
      hostCfg = config.hostCfg;
    };

    useUserPackages = true;
    useGlobalPkgs = true;

    # users.${hostCfg.username}.imports = [
    #   (
    #   { config, ... }:
    #   import ./hm {
    #     inherit
    #         pkgs
    #         inputs
    #         config
    #         lib
    #         hostCfg
    #         ;
    #   }
    #   )
    # ];
    users.${hostCfg.username} = {
      imports = [
        ./programs/git.nix
        ./programs/bash.nix
        ./programs/tmux.nix
        ./programs/vim.nix
        ./packages.nix
      ];
      home = {
        # imports = [
        #  #  ./programs/git.nix
        #  #  ./programs/bash.nix
        #  #  ./programs/tmux.nix
        #  #  ./programs/vim.nix
        #   ./packages.nix
        # ];
        # packages = with pkgs; [
        #     # busybox
        #     fzf
        #     git
        #     go
        #     htop
        #     htop
        #     iotop
        #     kubectl
        #     kubernetes-helm
        #     lynx
        #     mc
        #     neofetch
        #     neovim
        #     nmon
        #     ripgrep # needed by neovim telescope grep
        #     python3
        #     nodejs_23
        #     rsync
        #     rclone
        #     sops
        #     starship
        #     sublime4
        #     tmux
        #     vscode
        #     x11vnc
        # ];

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
        stateVersion = "24.11";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

  # With nixOS and hm, it wont be intalled,
  # use instead: nixos-rebuild switch --flake .#asdf
  # programs.home-manager.enable = true;

}
