{
  pkgs,
  config,
  ...
}:
let
  # wifiList       = [ "house" "house5" ];
  # netManProfiles = config.hostCfg._lib.genNetManProfiles wifiList ;
  # lel = builtins.trace "Value of myAttr: ${builtins.toJSON kek}" kek ;
  _hostCfg        = config.hostCfg ;
in
{

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

  networking.networkmanager.ensureProfiles.profiles = _hostCfg.genNetMan ;

  home-manager.users.${_hostCfg.username} = {

    home.packages = with pkgs; [
      chromium
    ] ++ (with pkgs.gnomeExtensions; [
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
          enabled-extensions = [
            "dash-to-panel@jderose9.github.com"
          ];
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
