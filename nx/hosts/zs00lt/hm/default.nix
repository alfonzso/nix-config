{ config, lib, pkgs, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  # ProjectRoot = config.hostCfg.root;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs";

in {

  home-manager = {
    extraSpecialArgs = {
      # inherit pkgs inputs;
      hostCfg = config.hostCfg;
    };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {

      imports = [ "${_hm_programs}" ./packages.nix ];

      programs.home-manager.enable = true;

      systemd.user.services.clone-my-stuff = {
        Unit = {
          Description = "Clone my github  configuration if missing";
          After = [ "default.target" ];
        };

        Service = {
          Type = "oneshot";
          Environment =
            "PATH=${lib.makeBinPath [ pkgs.curl pkgs.git pkgs.openssh ]}:/run/current-system/sw/bin";
          ExecStart = pkgs.writeShellScript "clone-my-stuff" ''
            set -ex
            NVIM_DIR="$HOME/.config/nvim"
            NIX_CFG_DIR="$HOME/workspace/home/nix/nix-config"
            NIX_SEC_DIR="$HOME/workspace/home/nix/nix-secret"

            if [ ! -d "$NVIM_DIR" ]; then
              echo "Cloning Neovim config..."
              git clone git@github.com:alfonzso/nvim.git $NVIM_DIR
            fi

            if [ ! -d "$NIX_CFG_DIR" ]; then
              echo "Cloning Nix config..."
              mkdir -p "$NIX_CFG_DIR"
              git clone git@github.com:alfonzso/nix-config $NIX_CFG_DIR
            fi

            if [ ! -d "$NIX_SEC_DIR" ]; then
              echo "Cloning Nix secrets..."
              mkdir -p "$NIX_SEC_DIR"
              git clone git@github.com:alfonzso/nix-secrets $NIX_SEC_DIR
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
