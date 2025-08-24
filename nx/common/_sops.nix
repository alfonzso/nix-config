{ pkgs, inputs, config, lib, NixSecrets, ProjectRoot, ... }:
let
  diffFiles = ProjectRoot + "/nx/common/scripts/diff_files.sh";
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;

  sshDir = NixSecrets + "/personal/ssh";

  # Recursively list all .yaml files under sshDir, returning relative paths
  listYamls = dir:
    lib.concatMap (name:
      let
        path = dir + "/" + name;
        dirTry = builtins.tryEval (builtins.readDir path);
      in if lib.strings.hasSuffix ".yaml" name then
        [ name ]
      else if dirTry.success then
        builtins.map (sub: name + "/" + sub) (listYamls path)
      else
        [ ]) (builtins.attrNames (builtins.readDir dir));

  _sshYamls = listYamls sshDir;

  # eee = builtins.elemAt sshYamls 0 ;
  # _sshYamls = builtins.trace eee sshYamls;

  sshSecrets = lib.listToAttrs (builtins.map (name:
    let
      filePath = sshDir + "/" + name;
      targetRel = lib.removeSuffix ".yaml" name;
      _name = "ssh/" + targetRel;
    in {
      name = builtins.trace _name _name;
      value = {
        sopsFile = filePath;
        key = "data";
      };
    }) _sshYamls);

  generatedWifiSopsSecret = builtins.listToAttrs (map (name: {
    name = "wifi/${name}";
    value = { };
  }) config.hostCfg.network.wifiNames);

in {

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.currentConfigName}.yaml";
    # validateSopsFiles = true;

    age.keyFile = "/tmp/keys.txt";

    secrets = lib.mkMerge [
      {
        root = { neededForUsers = true; };
        ${hostCfg.username} = { neededForUsers = true; };
      }
      sshSecrets
      generatedWifiSopsSecret
    ];

    templates."wifi.env".content = lib.concatStringsSep "\n" (map (name:
      ''
        WIFI_${lib.strings.toUpper name}="${
          config.sops.placeholder."wifi/${name}"
        }"'') config.hostCfg.network.wifiNames);

  };

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
