{
  inputs,
  config,
  pkgs,
  lib,
  ProjectRoot,
  ...
}:
let
  _mods        =  ProjectRoot + "/nx/modules" ;
  hostCfg      = config.hostCfg ;
in
{
  system.stateVersion = "25.05";

  hardware.enableRedistributableFirmware = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  imports = lib.flatten [
    ./hm 

    ./config.nix
    ./hardware-configuration.nix

    # no desktop for servers
    # "${_mods}/desktop/gnome.gdm.nix"

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
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
