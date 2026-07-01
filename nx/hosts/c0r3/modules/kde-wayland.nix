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

  home-manager.users.${hostCfg.username} = {
    programs.plasma = {
      enable = true;

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
        plasmarc.Theme.name = "breeze-dark";

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
