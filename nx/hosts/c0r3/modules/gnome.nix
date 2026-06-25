{ config, pkgs, ... }:
let
  hostCfg = config.hostCfg;
in
{
  imports = [ ./firefox.nix ];

  services.xserver.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = hostCfg.username;
    };
    gdm.enable = true;
  };
  services.desktopManager.gnome.enable = true;
  services.flatpak.enable = true;

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

  home-manager.users.${hostCfg.username} = { lib, ... }: {
    home.packages = with pkgs; [
      google-chrome
      signal-desktop
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-panel
      gnomeExtensions.desktop-icons-ng-ding
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

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-ac-timeout = 0;
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-battery-timeout = 0;
        };

        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-panel@jderose9.github.com"
            "ding@rastersoft.com"
            "gsconnect@andyholmes.github.io"
            "system-monitor@gnome-shell-extensions.gcampax.github.com"
          ];
        };

        "org/gnome/shell/extensions/dash-to-panel" = {
          panel-size = 48;
          appicon-margin = 4;
          multi-monitors = true;
          panel-element-positions-monitors-sync = true;
          primary-monitor = "1";
        };
      };
    };

    xdg.configFile."systemd/user/org.gnome.Shell@user.service.d/persistent-virtual-monitor.conf" = {
      force = true;
      text = ''
        [Service]
        ExecStart=
        ExecStart=/run/current-system/sw/bin/gnome-shell --mode=user --virtual-monitor 1920x1080@60
      '';
      onChange = "${pkgs.systemd}/bin/systemctl --user daemon-reload || true";
    };

    home.activation.removeOldGnomeWaylandVirtualMonitorDropin =
      lib.hm.dag.entryAfter [ "writeBoundary" ]
        ''
          ${pkgs.coreutils}/bin/rm -f "$HOME/.config/systemd/user/org.gnome.Shell@wayland.service.d/persistent-virtual-monitor.conf"
          ${pkgs.coreutils}/bin/rmdir --ignore-fail-on-non-empty "$HOME/.config/systemd/user/org.gnome.Shell@wayland.service.d" 2>/dev/null || true
        '';
  };
}
