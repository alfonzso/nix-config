{
  # inputs,
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
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    #inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14
    ./hardware-configuration.nix


    # ./nx/modules/_sops.nix
    # ./nx/modules/_ssh.nix
    # ./nx/modules/_networking.nix
    # ./nx/modules/_user.nix

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  hostCfg.root = PROJECT_ROOT ;
  hostCfg.username = "zsolt" ;
  # hostCfg.hostname = "zs00lt" ;
  hostCfg.hostname = HostName + "Nix" ;

  # _SOPS.dsf =  __secrets + "/secrets.yaml" ; 

  environment.systemPackages = with pkgs; [
    openssh
  ];

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "24.11";

  home-manager = {
    extraSpecialArgs = {
      # inherit pkgs inputs;
      inherit pkgs ;
      hostCfg = config.hostCfg;
    };
    users.${hostCfg.username}.imports = [
      (
      { config, ... }:
      # import ./nx/modules/home.nix {
      import ./hm {
        inherit
            # inputs
            config
            hostCfg
            lib
            pkgs
            ; 
      }
      )
    ];
  };
}
