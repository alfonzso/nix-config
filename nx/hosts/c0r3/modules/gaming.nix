{ config, pkgs, ... }: {
  hardware.steam-hardware.enable = true;

  systemd.tmpfiles.rules = [ "d /games 0775 ${config.hostCfg.username} users -" ];

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;

    steam = {
      enable = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };

  environment.systemPackages = with pkgs; [
    gamescope
    goverlay
    mangohud
    vulkan-tools

    bottles
    heroic
    lutris
    protonup-qt
    winePackages.staging
    winetricks
  ];
}
