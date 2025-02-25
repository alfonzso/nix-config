{
  inputs,
  config,
  pkgs,
  lib,
  # HostName,
  ProjectRoot,
  # KeK,
  ...
}:
let
  _mods        =  ProjectRoot + "/nx/modules" ;
  # inherit (import config.hostCfg) hostCfg; 
  # inherit (hostCfg) config.hostCfg ; 
  hostCfg      = config.hostCfg ;
  # hostCfg      = KeK ;
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

    "${_mods}/desktop/gnome.gdm.nix"

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  # hostCfg.root = ProjectRoot ;
  # hostCfg.username = "zsolt" ;
  # hostCfg.hostname = HostName ;

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
