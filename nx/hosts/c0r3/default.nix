{
  config,
  lib,
  pkgs,
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

  security.rtkit.enable = true;

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

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig."99-c0r3-audio-profile" = {
        "monitor.alsa.rules" = [
          {
            matches = [ { "device.name" = "alsa_card.pci-0000_00_1f.3"; } ];
            actions."update-props" = {
              "device.profile" = "pro-audio";
            };
          }
          {
            matches = [ { "device.name" = "alsa_card.pci-0000_01_00.1"; } ];
            actions."update-props" = {
              "device.profile" = "off";
            };
          }
        ];
      };
    };
  };
  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    alsa-utils
    pavucontrol
    pulseaudio
  ];

  home-manager.users.${config.hostCfg.username} =
    { lib, ... }:
    {
      home.activation.seedC0r3AudioState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.python3}/bin/python3 ${./scripts/seed-wireplumber-audio-state.py}
      '';
    };

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
