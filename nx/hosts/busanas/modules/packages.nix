{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libva-utils
    lm_sensors
    pciutils
    smartmontools
    usbutils
  ];
}
