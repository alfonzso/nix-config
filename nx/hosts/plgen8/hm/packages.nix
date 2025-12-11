{ config, pkgs, ... }:

{
  home.packages = with pkgs; [

    kubectl
    kubernetes-helm
    podman

    # needed by nvim
    neovim
    python312
    poetry
    lua-language-server
    go
    nodejs_24
    rustc
    cargo
    ripgrep
    fzf
    fd
    ripgrep-all

    sops
    age

    dig
    htop
    iotop
    ncdu
    nmon
    pciutils # lspci
    ps # ps aux
    socat
    # unixtools.net-tools
    nettools
    usbutils # lsusb

    bat
    git
    mc
    direnv
    neofetch
    rclone
    rename
    starship
    tldr
    tmux
    unzip

    yq
    jq

  ];
}
