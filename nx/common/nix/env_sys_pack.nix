{ pkgs, ... }: {

  config = {

    environment.systemPackages = with pkgs; [

      # for neovim to x11 clipboard sync
      # or not just neovim ...
      xclip

      lua-language-server
      stylua

      rsync
      screen
      openssh
      bash-completion
      gcc
      cargo
      cmake
      gnumake
      fzf
      trash-cli
      wl-clipboard

      wget
      curl
      tree
      inetutils # telnet

      restic
      wireguard-tools

    ];

  };
}
