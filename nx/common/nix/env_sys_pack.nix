{ pkgs, ... }: {

  config = {

    environment.systemPackages = with pkgs; [

      lua-language-server
      stylua

      rsync
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

      restic
      wireguard-tools

    ];

  };
}
