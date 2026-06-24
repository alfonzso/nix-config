{
  config,
  NixSecrets,
  pkgs,
  ...
}:
let
  hostCfg = config.hostCfg;
  sopsFolder = NixSecrets + "/sops";
  credentials = config.sops.templates."plgen8-samba-credentials".path;
  commonOptions = [
    "credentials=${credentials}"
    "uid=${hostCfg.username}"
    "gid=users"
    "file_mode=0664"
    "dir_mode=0775"
    "iocharset=utf8"
    "nofail"
    "noauto"
    "x-systemd.automount"
    "x-systemd.idle-timeout=10min"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=10s"
  ];
in
{
  environment.systemPackages = with pkgs; [
    cifs-utils
    samba
  ];

  sops = {
    secrets.samba_user_pwd = {
      owner = hostCfg.username;
      sopsFile = "${sopsFolder}/plgen8.yaml";
    };

    templates."plgen8-samba-credentials".content = ''
      username=${hostCfg.nasUser}
      password=${config.sops.placeholder.samba_user_pwd}
    '';
  };

  systemd.tmpfiles.rules = [ "d /mnt/plgen8 0755 root root -" ];

  fileSystems = {
    "/mnt/plgen8/secure" = {
      device = "//plgen8Nix/secure";
      fsType = "cifs";
      options = commonOptions;
    };

    "/mnt/plgen8/fast" = {
      device = "//plgen8Nix/fast";
      fsType = "cifs";
      options = commonOptions;
    };
  };
}
