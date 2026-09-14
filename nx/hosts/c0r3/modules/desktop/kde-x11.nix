{ config, pkgs, ... }:
let
  hostCfg = config.hostCfg;
in
{
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

  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "dbus-run-session startplasma-x11";
  };

  services.logind.settings.Login.IdleAction = "ignore";

  systemd.services.c0r3-power-profile-performance = {
    description = "Set c0r3 power profile to performance";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
    };
  };

  # NOTE: was disabled cuz of openblas slow building
  # environment.plasma6.excludePackages = with pkgs.kdePackages; [ spectacle ];

  environment.systemPackages = with pkgs; [
    cifs-utils
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.kio-extras
    kdePackages.konsole
    ntfs3g
    samba
  ];
}
