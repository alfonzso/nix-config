{ pkgs, inputs, config, lib, NixSecrets, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
in {

  systemd.tmpfiles.rules = [ "d /backup 0755 ${hostCfg.username} users -" ];

  system.activationScripts.deploySshConfigs = let
    sshFolder = "/home/${hostCfg.username}/.ssh";
    secretSshFolderPath =
      lib.removeSuffix "/config" config.sops.secrets."ssh/config".path;
  in {
    text = ''
      if [[ -d ${sshFolder} ]] ; then
        now=$(date +"%Y_%m_%d__%H_%M_%S")
        cp -r ${sshFolder} /backup/ssh_$now
        echo "~/.ssh folder saved to here: /backup/ssh_$now"
      fi
      ${pkgs.rsync}/bin/rsync -az ${secretSshFolderPath}/ ${sshFolder}
      chown -R ${hostCfg.username}:users ${sshFolder}
      chmod 700 ${sshFolder}
      find ${sshFolder} -type f -exec chmod 600 {} +
    '';
    deps = [ "setupSecrets" ];
  };

}
