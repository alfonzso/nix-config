{
  config,
  pkgs,
  ...
}:

{

  home = {
    packages = with pkgs; [
      neofetch
      tmux
      vim
      htop
      iotop
      nmon
    ];
  };
}
