{ lib, pkgs, ... }: {
  systemd.user.services = {

    my-worker = {
      Unit = {
        Description = "Init nvim --headless";
        After = [ "clone-my-stuff.service" ];
        Requires = [ "clone-my-stuff.service" ];
      };

      Service = {
        Type = "simple";
        Environment = with pkgs;
          "PATH=${
            lib.makeBinPath [
              git
              neovim
              (rust-bin.selectLatestNightlyWith (toolchain:
                toolchain.default.override {
                  extensions = [ "rust-src" "rust-analyzer" ];
                }))
            ]
          }:/run/current-system/sw/bin";
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = pkgs.writeShellScript "init-nvim" ''
          set -ex
          nvim --headless "+Lazy! restore" "+MasonToolsInstallSync" +qa
        '';
        Restart = "no";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    clone-my-stuff = {
      Unit = {
        Description = "Clone my github configuration if missing";
      };

      Service = {
        Type = "oneshot";
        Environment = with pkgs;
          "PATH=${
            lib.makeBinPath [ curl git openssh ]
          }:/run/current-system/sw/bin";
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
  };
}
