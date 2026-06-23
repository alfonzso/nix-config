{ config, pkgs, ... }: {
  hardware.steam-hardware.enable = true;

  systemd.tmpfiles.rules =
    [ "d /games 0775 ${config.hostCfg.username} users -" ];

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;

    steam = {
      enable = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };

  environment.systemPackages = with pkgs; [
    bottles
    gamescope
    goverlay
    heroic
    lutris
    mangohud
    protonup-qt
    vulkan-tools
    wineWow64Packages.staging
    winetricks
  ];
}
