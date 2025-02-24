{
  inputs,
  config,
  pkgs,
  lib,
  HostName,
  ProjectRoot,
  ...
}:
let
  _mods        =  ProjectRoot + "/nx/modules" ;
  hostCfg      = config.hostCfg ;
in
{
  system.stateVersion = "24.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  imports = lib.flatten [
    ./desktop
    ./hardware-configuration.nix

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  hostCfg.root = ProjectRoot ;
  hostCfg.username = "zsolt" ;
  hostCfg.hostname = HostName ;

  environment.systemPackages = with pkgs; [
    openssh
    bash-completion
    gcc
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
