{ pkgs, config, lib, ... }:
let hostCfg = config.hostCfg;
in {

  systemd.tmpfiles.rules = [ "d /backup 0755 ${hostCfg.username} users -" ];

  system.activationScripts.manageSshConfig = let
    sshFolder = "/home/${hostCfg.username}/.ssh";
    secretSshFolderPath =
      lib.removeSuffix "/config" config.sops.secrets."ssh/config".path;

    manageScript = pkgs.writeShellScript "manage-ssh"
      (builtins.readFile ./manage_ssh.sh);
    logFile = "/var/log/manage_ssh.log";
  in {
    text = ''
      ${manageScript} ${sshFolder} ${secretSshFolderPath} ${hostCfg.username} &>> ${logFile}
    '';
    deps = [ "setupSecrets" ];
  };

}
