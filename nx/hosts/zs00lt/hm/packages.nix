{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ncdu
    ps # ps aux
    usbutils # lsusb
    pciutils # lspci
    jq
    yq
    unzip
    dig
    git
    go
    htop
    iotop
    kubectl
    kubernetes-helm
    lynx
    mc
    neofetch
    neovim
    nmon
    ripgrep # needed by neovim telescope grep
    python3
    nodejs_24
    rclone
    sops
    starship
    sublime4
    tmux
    vscode
    x11vnc
  ];
}
