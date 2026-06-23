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

  home-manager.users.${hostCfg.username} = { lib, pkgs, ... }: {
    home.packages = with pkgs; [
      firefox
      google-chrome
    ];

    home.activation.setPlasmaDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key Name "Breeze Dark"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-dark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group WM --key colorScheme BreezeDark
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasmarc --group Theme --key name breeze-dark

      for profile in AC Battery LowBattery; do
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group SuspendAndShutdown --key AutoSuspendAction 0
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file powerdevilrc --group "$profile" --group SuspendAndShutdown --key AutoSuspendIdleTimeoutSec 0
      done

      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 20 --group Configuration --group Appearance --key dateFormat isoDate
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 20 --group Configuration --group Appearance --key firstDayOfWeek 1
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 20 --group Configuration --group Appearance --key showWeekNumbers true

      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 13 --key plugin org.kde.plasma.clipboard
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --key plugin org.kde.plasma.weather
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group Units --key pressureUnit 5007
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group Units --key speedUnit 9001
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group Units --key temperatureUnit 6001
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group Units --key visibilityUnit 2007
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group WeatherStation --key placeDisplayName "Budapest, Hungary, HU"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group WeatherStation --key placeInfo "Budapest, Hungary, HU|3054643"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group Applets --group 17 --group Configuration --group WeatherStation --key provider bbcukmet
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group General --key extraItems "org.kde.kdeconnect,org.kde.plasma.mediacontroller,org.kde.plasma.cameraindicator,org.kde.plasma.manage-inputmethod,org.kde.plasma.devicenotifier,org.kde.plasma.notifications,org.kde.plasma.clipboard,org.kde.plasma.keyboardlayout,org.kde.plasma.battery,org.kde.plasma.volume,org.kde.plasma.keyboardindicator,org.kde.plasma.weather,org.kde.plasma.networkmanagement,org.kde.plasma.bluetooth,org.kde.kscreen,org.kde.plasma.brightness"
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 2 --group Applets --group 7 --group General --key knownItems "org.kde.kdeconnect,org.kde.plasma.mediacontroller,org.kde.plasma.cameraindicator,org.kde.plasma.manage-inputmethod,org.kde.plasma.devicenotifier,org.kde.plasma.notifications,org.kde.plasma.clipboard,org.kde.plasma.keyboardlayout,org.kde.plasma.battery,org.kde.plasma.volume,org.kde.plasma.keyboardindicator,org.kde.plasma.weather,org.kde.plasma.networkmanagement,org.kde.plasma.bluetooth,org.kde.kscreen,org.kde.plasma.brightness"
    '';
  };
}
