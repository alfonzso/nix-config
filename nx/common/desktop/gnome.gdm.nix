{ pkgs, config, ... }:
let
  # wifiList       = [ "house" "house5" ];
  # netManProfiles = config.hostCfg._lib.genNetManProfiles wifiList ;
  # lel = builtins.trace "Value of myAttr: ${builtins.toJSON kek}" kek ;
  _hostCfg = config.hostCfg;
in {

  # services.avahi = {
  #   enable = true;          # Ensure this is set
  #   nssmdns = true;         # Also disable mDNS lookup if present
  #   openFirewall = true;    # Disable any firewall rules
  # };
  services.avahi = {
    enable = false;          # Ensure this is set
    nssmdns = false;         # Also disable mDNS lookup if present
    openFirewall = false;    # Disable any firewall rules
  };

  # programs.dconf.enable = true; 

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
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

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

  # extra browsers
  # chromium

  # services.gnome.chrome-gnome-shell.enable = true;


  home-manager.users.${_hostCfg.username} = {

    home.packages = with pkgs;
      [ chromium ] ++ (with pkgs.gnomeExtensions; [
        system-monitor
        # blur-my-shell
        dash-to-panel
      ]);
    # ];

    dconf = {
      enable = true;
      # settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
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
