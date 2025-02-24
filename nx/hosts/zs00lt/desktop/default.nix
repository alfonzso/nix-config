{
  pkgs,
  config,
  ...
}:
let
  wifiList = [ "house" "house5" ];
  kek = config.hostCfg._lib.genNetManProfiles wifiList ;
  lel = builtins.trace "Value of myAttr: ${builtins.toJSON kek}" kek ;
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

  networking.networkmanager.ensureProfiles.profiles = lel ;
  # networking.networkmanager.ensureProfiles = builtins.trace "kek: " config.hostCfg._lib.genNetManProfiles wifiList ;
  # networking.networkmanager.ensureProfiles = builtins.trace "kek: " config.hostCfg._lib.genNetManProfiles wifiList ;

  # networking.networkmanager.ensureProfiles = {
  #   "house" = {
  #     connection = {
  #       id = "house";
  #       type = "wifi";
  #       # uuid = "YOUR_GENERATED_UUID";  # Generate with `uuidgen`
  #     };
  #     wifi = {
  #       ssid = "house";
  #       mode = "infrastructure";
  #     };
  #     wifi-security = {
  #       key-mgmt = "wpa-psk";
  #       # psk = "your-wifi-password";  # Or use a hashed PSK (see below)
  #       psk = "your-wifi-password";  # Or use a hashed PSK (see below)
  #     };
  #   };
  # };
}
