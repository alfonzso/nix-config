{ config, pkgs, ... }: {
  hardware.steam-hardware.enable = true;

  systemd.tmpfiles.rules =
    [ "d /games 0775 ${config.hostCfg.username} users -" ];

  programs = {
    gamemode.enable = true;
    gamescope.enable = true;

    steam = {
      # Enable after the base install; Steam forces 32-bit graphics support.
      enable = false;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = false;
      remotePlay.openFirewall = false;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };

  environment.systemPackages = with pkgs; [
    gamescope
    goverlay
    mangohud
    vulkan-tools

    # Enable after the base install; these pull in Wine/32-bit compatibility.
    # bottles
    # heroic
    # lutris
    # protonup-qt
    # winePackages.staging
    # winetricks
  ];
}
