{
  inputs,
  config,
  pkgs,
  lib,
  ProjectRoot,
  ...
}:
let
  _common     =  ProjectRoot + "/nx/common" ;
  hostCfg      = config.hostCfg ;
in
{
  system.stateVersion = "24.11";

  hardware.enableRedistributableFirmware = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  imports = lib.flatten [
    ./hm 

    ./config.nix
    ./hardware-configuration.nix

    "${_common}/desktop/gnome.gdm.nix"

    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"

    ./sops.nix
  ];

  environment.systemPackages = with pkgs; [
    openssh
    bash-completion
    gcc
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

}
