{
  config,
  pkgs,
  ...
}:
let
  username = config.hostCfg.username;
  group = config.hostCfg.nasGroup;
in
{
  systemd.services.busanas-media-permissions = {
    description = "Prepare the mounted busanas media filesystem";
    wantedBy = [ "multi-user.target" ];
    after = [ "srv-media.mount" ];
    requires = [ "srv-media.mount" ];
    unitConfig.ConditionPathIsMountPoint = "/srv/media";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/chown ${username}:${group} /srv/media
      ${pkgs.coreutils}/bin/chmod 2775 /srv/media
      ${pkgs.coreutils}/bin/install -d -m 2775 \
        -o ${username} -g ${group} \
        /srv/media/incomplete /srv/media/watch
    '';
  };
}
