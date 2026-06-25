{ config, pkgs, ... }: {
  hardware.steam-hardware.enable = true;

  systemd.tmpfiles.rules = [
    "d /games 0775 ${config.hostCfg.username} users -"
    "d /games/SteamLibrary 0755 ${config.hostCfg.username} users -"
  ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  home-manager.users.${config.hostCfg.username}.xdg.configFile."sunshine/sunshine.conf" = {
    force = true;
    text = ''
      capture = portal
      output_name = Meta-0
    '';
    onChange = "${pkgs.systemd}/bin/systemctl --user restart sunshine || true";
  };

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
    sunshine
    vulkan-tools

    bottles
    heroic
    lutris
    protonup-qt
    winePackages.staging
    winetricks
  ];
}
