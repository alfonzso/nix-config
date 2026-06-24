{ config, pkgs, ... }:
let
  hostCfg = config.hostCfg;
in
{
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.flatpak.enable = true;

  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "dbus-run-session gnome-session";
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

  home-manager.users.${hostCfg.username} = {
    home.packages = with pkgs; [
      firefox
      google-chrome
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-panel
      gnomeExtensions.gsconnect
      gnomeExtensions.system-monitor
    ];

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          clock-format = "24h";
          clock-show-date = true;
          clock-show-weekday = true;
          cursor-size = 24;
          cursor-theme = "Adwaita";
          first-weekday = 1;
        };

        "org/gnome/desktop/session".idle-delay = 0;

        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-panel@jderose9.github.com"
            "gsconnect@andyholmes.github.io"
            "system-monitor@gnome-shell-extensions.gcampax.github.com"
          ];
        };

        "org/gnome/shell/extensions/dash-to-panel" = {
          panel-size = 48;
          appicon-margin = 4;
        };
      };
    };
  };
}
