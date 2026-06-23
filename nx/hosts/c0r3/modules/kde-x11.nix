{ config, pkgs, ... }:
let hostCfg = config.hostCfg;
in {
  services.xserver.enable = true;

  services.displayManager = {
    defaultSession = "plasmax11";
    sddm = {
      enable = true;
      wayland.enable = false;
    };
  };

  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.konsole
  ];

  home-manager.users.${hostCfg.username}.home.packages = with pkgs; [
    firefox
    google-chrome
  ];
}
