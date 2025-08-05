{ config , lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
in {

  system.stateVersion = "25.05";

  imports = lib.flatten [
    ./hardware-configuration.nix
    ./_global_host_config.nix

    ./modules/sops.nix

    "${_common}/_default_config.nix"

    # "${_common}/desktop/gnome.gdm.nix"
    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"

    ./hm
  ];

}
