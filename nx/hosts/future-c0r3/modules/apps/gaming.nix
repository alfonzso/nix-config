{
  config,
  pkgs,
  ...
}:
{
  imports = [ ./sunshine.nix ];

  hardware.steam-hardware.enable = true;

  systemd.tmpfiles.rules = [
    "d /games 0775 ${config.hostCfg.username} users -"
    "d /games/SteamLibrary 0755 ${config.hostCfg.username} users -"
  ];

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
    moonlight-qt
    vulkan-tools

    bottles
    cabextract
    curl
    heroic
    lutris
    p7zip
    protonup-qt
    protontricks
    winePackages.staging
    winetricks
    yad
  ];
}
