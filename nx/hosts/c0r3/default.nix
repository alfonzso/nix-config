{
  config,
  lib,
  ProjectRoot,
  ...
}:
let
  _common = ProjectRoot + "/nx/common";
  _activations = _common + "/activations";
in
{
  system.stateVersion = "25.11";

  users.users.${config.hostCfg.username}.extraGroups = [
    "audio"
    "input"
    "networkmanager"
    "render"
    "video"
  ];

  security.sudo.extraRules = [
    {
      users = [ config.hostCfg.username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  imports = lib.flatten [
    ./hm

    "${_common}/hm"

    ./modules/disko.nix
    ./modules/firefox.nix
    ./modules/flatpak.nix
    ./modules/gaming.nix
    ./modules/kde-wayland.nix
    ./modules/nvidia.nix
    ./modules/samba-client.nix

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${_activations}/manage_ssh.nix"

    "${_common}/sops"
    "${_common}/sops/ssh.nix"

    "${_common}/nix/common.nix"
    "${_common}/nix/config_nix.nix"
    "${_common}/nix/env_sys_pack.nix"

    "${_common}/networking"
    "${_common}/networking/bluetooth.nix"
    "${_common}/networking/ssh.nix"

    "${_common}/_virtualisation.nix"
    "${_common}/_user.nix"

    "${_common}/_b2_restic.nix"
  ];
}
