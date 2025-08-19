{ config, lib, pkgs, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  # ProjectRoot = config.hostCfg.root;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs" ;

in {

  home-manager = {
    extraSpecialArgs = {
      # inherit pkgs inputs;
      hostCfg = config.hostCfg;
    };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {

      imports = [
        "${_hm_programs}"
        ./packages.nix
      ];

      programs.home-manager.enable = true;

      systemd.user.services.clone-nvim-config = {
        Unit = {
          Description = "Clone Neovim configuration if missing";
          After = [ "default.target" ];
        };

        Service = {
          Type = "oneshot";
          Environment = "PATH=${lib.makeBinPath [ pkgs.curl pkgs.git pkgs.openssh ]}";
          ExecStart = pkgs.writeShellScript "clone-nvim" ''
            set -ex
            NVIM_DIR="$HOME/.config/nvim"
            if [ ! -d "$NVIM_DIR" ]; then
              echo "Cloning Neovim config..."
              git clone git@github.com:alfonzso/nvim.git $HOME/.config/nvim
            else
              echo "Neovim config already exists"
            fi
          '';
        };

        Install.WantedBy = [ "default.target" ];
      };
     
      xdg.enable = true;

      home = {
        # xdg.enable = true;

        activation.createCustomDir = lib.mkAfter ''
          mkdir -p ${vimTMP} || true
          chmod u+rw ${vimTMP}
        '';

        username = hostCfg.username;
        # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = "24.11";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

}
