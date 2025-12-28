{ lib, pkgs, ... }: {
  systemd.user.services.clone-my-stuff = {
    Unit = {
      Description = "Clone my github configuration if missing";
      After = [ "default.target" ];
    };

    Service = {
      Type = "oneshot";
      Environment = "PATH=${
          lib.makeBinPath [ pkgs.curl pkgs.git pkgs.openssh ]
        }:/run/current-system/sw/bin";
      ExecStart = pkgs.writeShellScript "clone-my-stuff" ''
        set -ex
        NVIM_DIR="$HOME/.config/nvim"
        NIX_CFG_DIR="$HOME/workspace/home/nix/nix-config"
        NIX_SEC_DIR="$HOME/workspace/home/nix/nix-secret"

        if [ ! -d "$NVIM_DIR" ]; then
          echo "Cloning Neovim config..."
          git clone git@github.com:alfonzso/nvim.git $NVIM_DIR
          nvim --headless "+Lazy! restore" "+MasonToolsInstallSync" +qa &
          NVIM_PID=$!
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

        wait $NVIM_PID
        echo "Nvim setup finished"

      '';
    };

    Install.WantedBy = [ "default.target" ];
  };
}
