{ lib, ProjectRoot, ... }:
let
  _common = ProjectRoot + "/nx/common";
  _desktop = ProjectRoot + "/nx/desktop";
  _activations = _common + "/activations";
in {

  system.stateVersion = "25.05";

  imports = lib.flatten [
    ./hm
    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/deploy_ssh_files.nix"
    "${_desktop}/gnome.gdm.nix"

    "${_common}/_nix_conf.nix"
    "${_common}/_common_and_sys_env.nix"
    "${_common}/_bluetooth.nix"
    "${_common}/_printer.nix"
    "${_common}/_virtualisation.nix"
    "${_common}/_sops.nix"
    "${_common}/_ssh.nix"
    "${_common}/_networking.nix"
    "${_common}/_user.nix"
    "${_common}/_b2_rclone.nix"

  ];

}
