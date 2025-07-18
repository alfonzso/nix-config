{
  inputs,
  config,
  pkgs,
  lib,
  ProjectRoot,
  ...
}:
let
  _modules     =  ProjectRoot + "/nx/modules" ;
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

    "${_modules}/desktop/gnome.gdm.nix"

    "${_modules}/_sops.nix"
    "${_modules}/_ssh.nix"
    "${_modules}/_networking.nix"
    "${_modules}/_user.nix"

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
