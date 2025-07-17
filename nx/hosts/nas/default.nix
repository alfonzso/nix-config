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
  # nixSecrets   = builtins.toString inputs.nix-secrets ;
in
{

  imports = lib.flatten [
    ./hm

    ./config.nix
    ./hardware-configuration.nix
    ./mounts.nix
    ./mergerfs.nix

    # no desktop for servers
    # "${_mods}/desktop/gnome.gdm.nix"

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  # options.nixSecrets = lib.mkOption {
  #   type    = lib.types.str;
  #   default = builtins.toString inputs.nix-secrets ;
  # };

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
