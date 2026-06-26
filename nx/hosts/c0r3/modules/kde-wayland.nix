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
    defaultSession = "plasma";
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
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

  home-manager.users.${hostCfg.username} = { lib, pkgs, ... }: {
    home.packages = with pkgs; [
      google-chrome
      signal-desktop
    ];

    home.activation.setPlasmaDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key Name "Breeze Dark"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-dark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group WM --key colorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasmarc --group Theme --key name breeze-dark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume false
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0

      for profile in AC Battery LowBattery; do
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group DimDisplay --key idleTime 0
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group DPMSControl --key idleTime 0
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group SuspendAndShutdown --key AutoSuspendAction 0
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group SuspendAndShutdown --key AutoSuspendIdleTimeoutSec 0
      done
    '';
  };
}
