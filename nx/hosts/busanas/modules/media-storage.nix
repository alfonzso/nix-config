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
  # Mode and ownership are left to busanas-media-permissions below. A rule that
  # pins them here would be re-applied on every activation, and because the disk
  # is an automount, tmpfiles walks into the mounted filesystem and would reset
  # its root directory instead of the empty mountpoint.
  systemd.tmpfiles.rules = [ "d /srv/media - - - -" ];

  systemd.services.busanas-media-permissions = {
    description = "Prepare the mounted busanas media filesystem";
    wantedBy = [
      "multi-user.target"
      "srv-media.mount"
    ];
    bindsTo = [ "srv-media.mount" ];
    after = [
      "srv-media.mount"
      "systemd-tmpfiles-setup.service"
    ];
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
