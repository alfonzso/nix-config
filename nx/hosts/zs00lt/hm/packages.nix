{ config, pkgs, ... }:

{
  # home.packages = with pkgs; [
  # packages = with pkgs; [
  home.packages = with pkgs; [
    # busybox
    ps # ps aux
    usbutils # lsusb
    pciutils # lspci
    jq
    yq
    unzip
    fzf
    dig
    git
    go
    htop
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
    # nodejs_23
    nodejs_24
    # toybox
    # rsync # installed as systemPackage
    rclone
    sops
    starship
    sublime4
    tmux
    vscode
    x11vnc
  ];
}
