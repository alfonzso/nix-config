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
      # set -x
      export PATH=$PATH:/run/current-system/sw/bin/
      function md5FolderSum(){
        find $1 -type f -exec md5sum {} \; | sort | cut -d" " -f1 | md5sum
      }

      ssh_now=`md5FolderSum ${sshFolder} || date`
      ssh_backup=`md5FolderSum /backup/latest/ || date`

      if [[ -d ${sshFolder} ]] && [[ "$ssh_now" != "$ssh_backup" ]] ; then
        now=$(date +"%Y_%m_%d__%H_%M_%S")
        su ${hostCfg.username} -c "cp -r ${sshFolder} /backup/ssh_$now"
        rm /backup/latest
        su ${hostCfg.username} -c "ln -s /backup/ssh_$now /backup/latest"
        echo "~/.ssh folder saved to here: /backup/ssh_$now"
      fi
      ${pkgs.rsync}/bin/rsync -az ${secretSshFolderPath}/ ${sshFolder}
      chown -R ${hostCfg.username}:users ${sshFolder}
      chmod 700 ${sshFolder}
      find ${sshFolder} -type f -exec chmod 600 {} +
      set +x
    '';
    deps = [ "setupSecrets" ];
  };

}
