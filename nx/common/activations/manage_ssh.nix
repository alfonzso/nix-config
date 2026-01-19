{ pkgs, config, lib, ... }:
let hostCfg = config.hostCfg;
in {

  systemd.tmpfiles.rules = [ "d /backup 0755 ${hostCfg.username} users -" ];

  system.activationScripts.manageSshConfig = let
    sshFolder = "/home/${hostCfg.username}/.ssh";
    secretSshFolderPath =
      lib.removeSuffix "/config" config.sops.secrets."ssh/config".path;

    manageScript =
      pkgs.writeShellScript "manage-ssh" (builtins.readFile ./manage_ssh.sh);
    logFile = "/persist/manage_ssh.log";
    _PATH = with pkgs;
      "${lib.makeBinPath [ rsync ]}:/run/current-system/sw/bin";
  in {
    text = ''
      set -e
      export PATH=$PATH:${_PATH}
      ${manageScript} ${sshFolder} ${secretSshFolderPath} ${hostCfg.username} &>> ${logFile} || true
    '';
    deps = [ "setupSecrets" ];
  };

}
