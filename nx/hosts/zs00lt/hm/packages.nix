{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
      busybox
      fzf
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
      rsync
      sops
      sublime4
      tmux
      # vim
      vscode
      x11vnc
  ];
}
