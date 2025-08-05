{ config, inputs, pkgs, lib, ... }:
let
  _hostCfg = config.hostCfg ;
  _common = _hostCfg.root + "/nx/common" ;
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

    "${_common}/_default_config.nix"
    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"

  ];

    system.stateVersion = "25.05";

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

}
