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

  # NOTE: was disabled cuz of openblas slow building
  # environment.plasma6.excludePackages = with pkgs.kdePackages; [ spectacle ];

  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.konsole
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
    '';
  };
}
