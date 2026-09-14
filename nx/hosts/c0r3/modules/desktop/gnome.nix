{ config, pkgs, ... }:
let
  hostCfg = config.hostCfg;
in
{
  services.xserver.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = hostCfg.username;
    };
    gdm.enable = true;
  };
  services.desktopManager.gnome.enable = true;

  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "dbus-run-session gnome-session";
  };

  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
    suspend-then-hibernate.enable = false;
  };

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

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gedit
    gnome-characters
    gnome-music
    gnome-photos
    gnome-tour
    hitori
    tali
    totem
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    ntfs3g
  ];
}
