{
  config,
  currentConfigName,
  inputs,
  lib,
  ProjectRoot,
  ...
}:
let
  common = ProjectRoot + "/nx/common";
  activations = common + "/activations";
  username = config.hostCfg.username;
in
{
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.configurationLimit = 5;
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  users.groups.busa.gid = 1000;
  users.users.${username} = {
    uid = 1000;
    group = "busa";
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "render"
      "video"
    ];
  };

  security.rtkit.enable = true;

  networking = {
    nftables.enable = true;
    firewall.enable = true;
    networkmanager.ensureProfiles.profiles.busanas-ethernet = {
      connection = {
        id = "busanas-ethernet";
        type = "ethernet";
        interface-name = "eno2";
        autoconnect = true;
        autoconnect-priority = 100;
      };
      ethernet = { };
      ipv4.method = "auto";
      ipv6.method = "disabled";
    };
  };

  systemd.tmpfiles.rules = [
    "d /persist 0700 root root -"
    "d /persist/sops 0700 root root -"
    "d /persist/sops/age 0700 root root -"
  ];

  imports = lib.flatten [
    (builtins.getAttr currentConfigName inputs.home-manager-config.homeManagerModules.hosts)

    "${common}/hm"

    ./modules/disko.nix
    ./modules/gnome.nix
    ./modules/media-storage.nix
    ./modules/packages.nix
    ./modules/samba.nix
    ./modules/sunshine.nix

    ./hardware-configuration.nix
    ./_global_host_config.nix

    "${activations}/manage_ssh.nix"

    "${common}/sops"
    "${common}/sops/ssh.nix"
    "${common}/sops/wifi.nix"

    "${common}/nix/common.nix"
    "${common}/nix/config_nix.nix"
    "${common}/nix/env_sys_pack.nix"

    "${common}/networking"
    "${common}/networking/bluetooth.nix"
    "${common}/networking/ssh.nix"

    "${common}/_user.nix"
  ];
}
