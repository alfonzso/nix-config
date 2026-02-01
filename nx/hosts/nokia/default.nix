{ lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _desktop = ProjectRoot + "/nx/desktop";
  _activations = _common + "/activations";
in
{

  system.stateVersion = "25.11";

  # nixpkgs.overlays = [
  #   (final: prev: {
  #
  #     intune-portal = prev.intune-portal.overrideAttrs (oldAttrs: rec {
  #       version = "1.2511.11-noble";
  #       src = prev.fetchurl {
  #         url =
  #           "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/i/intune-portal/intune-portal_${version}_amd64.deb";
  #         sha256 = "1i57pnp75kalyi7f9b3xaa37bs4x87fckcxwljlmd4cpacxnpd9h";
  #       };
  #     });
  #
  #     microsoft-identity-broker = prev.microsoft-identity-broker.overrideAttrs
  #       (oldAttrs: rec {
  #         version = "2.5.1-noble";
  #         src = prev.fetchurl {
  #           url =
  #             "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/microsoft-identity-broker/microsoft-identity-broker_${version}_amd64.deb";
  #           sha256 = "0adsqiq5a4jdgjgnj3hpmk6bhw55z6mbx97y317pkvr8svzgyymw";
  #         };
  #       });
  #   })
  # ];

  nix.settings = {
    # include both the default Nix cache and Himmelblau Cachix
    substituters = [ "https://himmelblau.cachix.org" ];
    trusted-public-keys = [
      "himmelblau.cachix.org-1:yu8mq/NIBYsZHWzo4SOge97gpf02qugdZFT/JdRkswc="
    ];
  };

  imports = lib.flatten [

    ./hm
    "${_common}/hm"

    ./modules/disko.nix
    ./modules/sops.nix
    ./modules/networking.nix
    ./modules/himmelblau.nix

    # not working/needed
    # ./modules/microsoft.nix

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/manage_ssh.nix"

    "${_desktop}/gnome.gdm.nix"

    "${_common}/sops"
    "${_common}/sops/ssh.nix"
    "${_common}/sops/wifi.nix"

    "${_common}/nix/common.nix"
    "${_common}/nix/config_nix.nix"
    "${_common}/nix/env_sys_pack.nix"

    "${_common}/networking"
    "${_common}/networking/ssh.nix"
    "${_common}/networking/bluetooth.nix"

    "${_common}/_virtualisation.nix"
    "${_common}/_user.nix"

    "${_common}/_b2_restic.nix"
  ];

}
