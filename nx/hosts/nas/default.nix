{
  inputs,
  config,
  pkgs,
  lib,
  ProjectRoot,
  ...
}:
let
  _common        =  ProjectRoot + "/nx/common" ;
  hostCfg      = config.hostCfg ;
in
{
  imports = lib.flatten [
    ./hm
    ./hardware-configuration.nix

    ./modules/config.nix
    # ./modules/mergerfs_4_samba.nix
    # ./modules/samba.nix
    ./modules/nfs.nix
    ./modules/mergerfs_4_nfs.nix
    ./modules/sops.nix

    ./modules/mounts.nix

    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"
  ];

  config = {

    system.stateVersion = "25.05";

    hardware.enableRedistributableFirmware = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    # nix.settings.trusted-public-keys = [
    #   "nas:owUPp8g4dg7pKBKQAqcB48gEYkZFAyw12IfpGDBEeeY="
    # ];

    # nix = {
    #   requireSignedBinaryCaches = false;
    #   extraOptions = ''
    #     require-sigs = false
    #   '';
    # };

    # nix.settings.require-sigs = false;

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

  };
}
