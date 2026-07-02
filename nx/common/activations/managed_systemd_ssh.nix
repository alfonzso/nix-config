{ pkgs, config, lib, ... }:
# Alternative to manage_ssh.nix that syncs ~/.ssh via a systemd service instead
# of a system.activationScripts snippet.
#
# Not imported by default. Use this instead of manage_ssh.nix on hosts where you
# do NOT want to force /home into the initrd (neededForBoot). It orders itself
# after local-fs.target (so /home is mounted) and runs at multi-user.target
# (after sops has rendered /run/secrets), so the copy always has both the
# destination filesystem and the source secrets available.
let
  hostCfg = config.hostCfg;

  sshFolder = "/home/${hostCfg.username}/.ssh";
  secretSshFolderPath =
    lib.removeSuffix "/config" config.sops.secrets."ssh/config".path;

  manageScript =
    pkgs.writeShellScript "manage-ssh" (builtins.readFile ./manage_ssh.sh);
  logFile = "/persist/manage_ssh.log";
in
{

  systemd.tmpfiles.rules = [ "d /backup 0755 ${hostCfg.username} users -" ];

  systemd.services.manage-ssh = {
    description = "Sync ~/.ssh for ${hostCfg.username} from sops secrets";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    path = with pkgs; [
      rsync
      coreutils
      findutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${manageScript} ${sshFolder} ${secretSshFolderPath} ${hostCfg.username}";
      StandardOutput = "append:${logFile}";
      StandardError = "append:${logFile}";
    };
  };

}
