{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
      # busybox
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
      python3
      nodejs_23
      rsync
      rclone
      sops
      starship
      sublime4
      tmux
      vscode
      x11vnc
  ];
}
