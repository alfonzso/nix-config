{
  config,
  inputs,
  pkgs,
  ...
}:
let
  hostCfg = config.hostCfg;
  wallpaperSource = ../../assets/starry-nebula-219.png;
  wallpaperPath = ".local/share/wallpapers/starry-nebula-219.png";
  carelinkKdebar = inputs.carelink-tui.packages.${pkgs.stdenv.hostPlatform.system}.carelink-kdebar;
in
{
  services.xserver.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = true;
      user = hostCfg.username;
    };
    defaultSession = "plasma";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.desktopManager.plasma6.enable = true;
  programs.kdeconnect.enable = true;

  services.xrdp = {
    enable = true;
    openFirewall = true;
    defaultWindowManager = "dbus-run-session startplasma-wayland";
  };

  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
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

  home-manager.users.${hostCfg.username} =
    { config, lib, ... }:
    {
      home.file.${wallpaperPath}.source = wallpaperSource;
      home.packages = [ carelinkKdebar ];

      programs.plasma = {
        enable = true;

        workspace.wallpaper = "${config.home.homeDirectory}/${wallpaperPath}";

        desktop.icons = {
          alignment = "left";
          arrangement = "topToBottom";
          size = 0;
          sorting = {
            mode = "manual";
            foldersFirst = true;
          };
        };

        panels = [
          {
            location = "bottom";
            height = 36;
            widgets = [
              "org.kde.plasma.kickoff"
              "org.kde.plasma.pager"
              {
                iconTasks.launchers = [
                  "applications:org.kde.kate.desktop"
                  "applications:sublime_text.desktop"
                  "applications:firefox.desktop"
                  "applications:google-chrome.desktop"
                  "applications:steam.desktop"
                  "applications:signal.desktop"
                  "applications:systemsettings.desktop"
                  "preferred://filemanager"
                  "applications:org.kde.konsole.desktop"
                  "applications:org.kde.plasma-systemmonitor.desktop"
                  "applications:com.usebottles.bottles.desktop"
                ];
              }
              "net.lehel.carelink.kdebar"
              "org.kde.plasma.marginsseparator"
              {
                name = "org.kde.plasma.weather";
                config.WeatherStation = {
                  placeDisplayName = "Budapest, Hungary, HU";
                  placeInfo = "Budapest, Hungary, HU|3054643";
                  provider = "bbcukmet";
                };
                config.Units = {
                  temperatureUnit = 6001; # Celsius
                  pressureUnit = 5008; # hPa
                  speedUnit = 9001; # km/h
                  visibilityUnit = 2007; # km
                };
              }
              "org.kde.plasma.systemtray"
              {
                digitalClock = {
                  date = {
                    enable = true;
                    format = "isoDate";
                  };
                  time.format = "24h";
                  calendar = {
                    firstDayOfWeek = "monday";
                    showWeekNumbers = true;
                  };
                };
              }
              "org.kde.plasma.showdesktop"
            ];
          }
        ];

        configFile = {
          kdeglobals = {
            General = {
              ColorScheme = "BreezeDark";
              Name = "Breeze Dark";
            };
            Icons.Theme = "breeze-dark";
            KDE.LookAndFeelPackage = "org.kde.breezedark.desktop";
            UiSettings.ColorScheme = "BreezeDark";
            WM.colorScheme = "BreezeDark";
          };

          kscreenlockerrc.Daemon.Lock = false;
          ksmserverrc.General.loginMode = "emptySession";
          kxkbrc.Layout = {
            DisplayNames = ",";
            LayoutList = "us,hu";
            Use = true;
            VariantList = ",";
          };
          plasmarc = {
            Theme.name = "breeze-dark";
            Wallpapers.usersWallpapers = "${config.home.homeDirectory}/${wallpaperPath}";
          };
          kwinrc = {
            NightColor.Active = true;
          };

          powerdevilrc = {
            "AC/DPMSControl" = {
              idleTime = 0;
              turnOffIdle = false;
            };
            "Battery/DPMSControl" = {
              idleTime = 0;
              turnOffIdle = false;
            };
            "LowBattery/DPMSControl" = {
              idleTime = 0;
              turnOffIdle = false;
            };
          };
        };

        kscreenlocker = {
          autoLock = false;
          lockOnResume = false;
          lockOnStartup = false;
          passwordRequired = false;
          timeout = 0;
        };

        powerdevil = {
          AC = {
            autoSuspend.action = "nothing";
            dimDisplay.enable = false;
            turnOffDisplay.idleTimeout = "never";
          };
          battery = {
            autoSuspend.action = "nothing";
            dimDisplay.enable = false;
            turnOffDisplay.idleTimeout = "never";
          };
          lowBattery = {
            autoSuspend.action = "nothing";
            dimDisplay.enable = false;
            turnOffDisplay.idleTimeout = "never";
          };
        };
      };
    };
}
