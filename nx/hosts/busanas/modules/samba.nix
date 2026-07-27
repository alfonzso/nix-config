{
  config,
  lib,
  ProjectRoot,
  ...
}:
let
  common = ProjectRoot + "/nx/common";
  sambaUser = config.hostCfg.nasUser;
in
{
  imports = [
    (common + "/fileshare/samba.nix")
  ];

  sops.secrets.samba_user_pwd.owner = config.hostCfg.username;

  services.samba = {
    openFirewall = lib.mkForce false;
    settings = lib.mkForce {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "busanas";
        "netbios name" = "busanas";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "server min protocol" = "SMB2_02";
        "interfaces" = "lo eno2 wlo1";
        "bind interfaces only" = "yes";
        "hosts allow" = "127.0.0.1 192.168.1.0/24";
        "hosts deny" = "0.0.0.0/0";
      };

      media = {
        path = "/srv/media";
        browseable = "yes";
        writable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = sambaUser;
        "write list" = sambaUser;
        "force user" = sambaUser;
        "force group" = config.hostCfg.nasGroup;
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  systemd.services.samba-smbd = {
    after = [
      "srv-media.mount"
      "busanas-media-permissions.service"
    ];
    requires = [
      "srv-media.mount"
      "busanas-media-permissions.service"
    ];
    unitConfig.ConditionPathIsMountPoint = "/srv/media";
  };

  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.0/24 tcp dport { 139, 445 } accept
    ip saddr 192.168.1.0/24 udp dport { 137, 138 } accept
  '';
}
