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

  boot.loader.systemd-boot.configurationLimit = 5;

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

  # Legacy audio recovery workarounds, kept here for quick rollback/debugging.
  #
  # These were added before the custom audio-capable HDMI EDID in
  # modules/hardware/nvidia.nix made the NVIDIA HDMI sink stable after reboot.
  # Leave them disabled while the new EDID path works, because forcing ALSA mixer
  # and WirePlumber user state can hide the real hardware state Plasma/PipeWire
  # detects at login.
  #
  # Re-enable the mixer service only if the motherboard analog 3.5mm output gets
  # muted again after reboot. Re-enable the WirePlumber state seeding only if the
  # built-in card profile keeps falling away from pro-audio.
  #
  # systemd.services.c0r3-analog-audio-mixer = {
  #   description = "Restore c0r3 analog audio mixer levels";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "sound.target" ];
  #   serviceConfig.Type = "oneshot";
  #   path = [ pkgs.alsa-utils ];
  #   script = ''
  #     amixer -c PCH set Master 100% unmute || true
  #     amixer -c PCH set PCM 100% || true
  #     amixer -c PCH set Front 100% unmute || true
  #     amixer -c PCH set Headphone 100% unmute || true
  #     amixer -c PCH set 'Auto-Mute Mode' Disabled || true
  #   '';
  # };
  #
  # home-manager.users.${config.hostCfg.username} = { lib, ... }: {
  #   home.activation.seedC0r3AudioState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #     ${pkgs.python3}/bin/python3 ${./scripts/seed-wireplumber-audio-state.py}
  #   '';
  # };

  imports = lib.flatten [
    ./hm

    "${_common}/hm"

    # Storage
    ./modules/storage/disko.nix

    # Desktop
    ./modules/desktop/kde-wayland.nix

    # Hardware
    ./modules/hardware/nvidia.nix

    # Apps and gaming
    ./modules/apps/firefox.nix
    ./modules/apps/flatpak.nix
    ./modules/apps/gaming.nix

    # Network fileshares
    ./modules/fileshare/samba-client.nix

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
