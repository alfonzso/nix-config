{ pkgs, inputs, config, lib, NixSecrets, ProjectRoot, ... }:
let
  diffFiles = ProjectRoot + "/nx/common/scripts/diff_files.sh";
  nxLib = ProjectRoot + "/nx/lib";
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;

  personalDir = NixSecrets + "/personal";
  personalSSHDir = personalDir + "/ssh";

  # yamlPaths = builtins.filterSource (path: type: type == "regular" && builtins.match ".*\\.ya?ml$" path != null) personalSSHDir;
  # yamlPaths = builtins.attrValues (builtins.filterSource (path: type: type == "regular" && builtins.match ".*\\.ya?ml$" path != null) personalSSHDir);

  # # Recursively list all .yaml files under personalSSHDir, returning relative paths
  # listYamls = dir:
  #   lib.concatMap (name:
  #     let
  #       path = dir + "/" + name;
  #       dirTry = builtins.tryEval (builtins.readDir path);
  #     in if lib.strings.hasSuffix ".yaml" name then
  #       [ name ]
  #     else if dirTry.success then
  #       builtins.map (sub: name + "/" + sub) (listYamls path)
  #     else
  #       [ ]) (builtins.attrNames (builtins.readDir dir));
  #
  # _sshYamls = listYamls personalSSHDir;
  #
  # sshSecrets = lib.listToAttrs (builtins.map (name:
  #   let
  #     filePath = personalSSHDir + "/" + name;
  #     targetRel = lib.removeSuffix ".yaml" name;
  #     _name = "ssh/" + targetRel;
  #   in {
  #     # name = builtins.trace _name _name;
  #     name = _name;
  #     value = {
  #       sopsFile = filePath;
  #       key = "data";
  #     };
  #   }) _sshYamls);
  #
  # _sshSecrets = builtins.trace sshSecrets sshSecrets;

  # allFiles = lib.filesystem.listFilesRecursive personalSSHDir;
  # yamlPaths = lib.filter (file: lib.strings.hasSuffix ".yaml" file || lib.strings.hasSuffix ".yml" file) allFiles;
  #
  # sshSecrets = lib.listToAttrs (builtins.map (sopsFilePath:
  #   let
  #     _name = builtins.unsafeDiscardStringContext (builtins.replaceStrings [ "${personalDir}/ssh/" ".yaml" ".yml" ] [ "" "" "" ] sopsFilePath) ;
  #   in {
  #     name = _name;
  #     value = {
  #       sopsFile = sopsFilePath;
  #       key = "data";
  #     };
  #   }) yamlPaths);
  #
  # sshSecrets =
  #     ( import "${nxLib}/_sops_ssh.nix" {
  #         inherit lib ;
  #         sshDir = personalSSHDir ;
  #       }
  #     ) ;
in  {

  # activ

  # system.activationScripts.testyaml = {
  #   text = ''
  #     echo ${yamlPaths}
  #   '';
  #   deps = [];
  # };

  # _keke = builtins.trace yamlPaths yamlPaths ;

  # system.extraDependencies = [
  #   # (builtins.trace yamlPaths yamlPaths)
  #   (builtins.trace personalSSHDir personalSSHDir)
  # ];

  # system.activationScripts.find-yamls = ''
  #   echo "Writing discovered YAML files to /run/found-yamls"
  #   echo ${yamlPaths}
  # '';

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.currentConfigName}.yaml";
    # validateSopsFiles = true;

    age.keyFile = "/tmp/keys.txt";

    secrets = lib.mkMerge [
      {
        root = { neededForUsers = true; };
        ${hostCfg.username} = { neededForUsers = true; };
      }

      ( import "${nxLib}/_sops_ssh.nix" { inherit lib; sshDir = personalSSHDir; })
      ( import "${nxLib}/_sops_wifi.nix" { wifiNames = config.hostCfg.network.wifiNames; })
    ];

    templates."wifi.env".content = lib.concatStringsSep "\n" (map (name:
      ''
        WIFI_${lib.strings.toUpper name}="${ config.sops.placeholder."wifi/${name}" }"
      ''
    ) config.hostCfg.network.wifiNames);

  };

}
