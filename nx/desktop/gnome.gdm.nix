{ pkgs, config, ... }:
let _hostCfg = config.hostCfg;
in {

  systemd.sockets.avahi-daemon = {
    after = [
      # Ensure that `/run/avahi-daemon` owned by `avahi` is created by `systemd.tmpfiles.rules` before the `avahi-daemon.socket`,
      # otherwise `avahi-daemon.socket` will automatically create it owned by `root`, which will cause `avahi-daemon.service` to fail.
      "systemd-tmpfiles-setup.service"
    ];
  };

  # services.avahi = {
  #   enable = false;          # Ensure this is set
  #   nssmdns = false;         # Also disable mDNS lookup if present
  #   openFirewall = false;    # Disable any firewall rules
  # };

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  # its not x11 forwarding or any other thing i thought
  # this config needed for gnome to be enabled
  services.xserver = {
    enable = true;
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = (with pkgs; [
    atomix # puzzle game
    # cheese # webcam tool
    epiphany # web browser
    # evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori # sudoku game
    # iagno # go game
    tali # poker game
    totem # video player
  ]);

  home-manager.users.${_hostCfg.username} = {

    # browsers
    home.packages = with pkgs;
      [
        firefox
        google-chrome
      ] ++ (with pkgs.gnomeExtensions; [
        system-monitor
        dash-to-panel
      ]);

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/shell" = {
          # Enable dash-to-panel and other extensions
          enabled-extensions = [ "dash-to-panel@jderose9.github.com" ];
        };

        # Optional: Customize dash-to-panel settings
        "org/gnome/shell/extensions/dash-to-panel" = {
          panel-size = 48;
          appicon-margin = 4;
        };
      };
    };
  };
}
