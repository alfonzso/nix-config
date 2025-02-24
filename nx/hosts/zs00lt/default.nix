{
  inputs,
  config,
  pkgs,
  lib,
  HostName,
  ...
}:
let
  # lib = pkgs.lib ;
  PROJECT_ROOT = builtins.toString ./. ;
  PROJECT_WS   = builtins.toString ./nx/. ;
  ws           = ./nx/. ;
  mods         =  "${PROJECT_WS}/modules" ;
  _mods        =  ../../modules/. ;
  secrets      =  "${PROJECT_WS}/secrets" ;
  __secrets    =  ws + "/secrets"  ;
  hostCfg      = config.hostCfg ;
in
{
  system.stateVersion = "24.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  imports = lib.flatten [
    ./hardware-configuration.nix

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  hostCfg.root = PROJECT_ROOT ;
  hostCfg.username = "zsolt" ;
  hostCfg.hostname = HostName ;

  environment.systemPackages = with pkgs; [
    openssh
  ];

  hardware.enableRedistributableFirmware = true;

  home-manager = {
    extraSpecialArgs = {
      inherit pkgs inputs;
      hostCfg = config.hostCfg;
    };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username}.imports = [
      (
      { config, ... }:
      import ./hm {
        inherit
            pkgs
            inputs
            config
            lib
            hostCfg
            ; 
      }
      )
    ];
  };
}
