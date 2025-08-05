{ inputs, config, lib, NixSecrets, ... }:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;
  # builtins.trace (builtins.toJSON sopsFolder)

  # Read all entries in the personal/ssh directory

  # import "${inputs.nix-secrets}/personal" { };
  # sshDir = inputs.nix-secrets/personal/ssh;
  sshDir = NixSecrets + "/personal/ssh";
  sshDirStr = toString sshDir;
  sshDirPrefixLen = builtins.stringLength sshDirStr + 1;  # include the slash

  # Recursively list all .yaml files under sshDir, returning relative paths
  listYamls = dir: lib.concatMap (name:
    let
      path = dir + "/" + name;
      dirTry = builtins.tryEval (builtins.readDir path);
    in if lib.strings.hasSuffix ".yaml" name then
         [ name ]
       else if dirTry.success then
         # Recurse and prepend subdirectory
         builtins.map (sub: name + "/" + sub) (listYamls path)
       else
         []
  ) (builtins.attrNames (builtins.readDir dir));

  sshYamls = listYamls sshDir;

  # sshYamls = builtins.filter (n: lib.strings.hasSuffix ".yaml" n) (builtins.attrNames (builtins.readDir sshDir));
  eee = builtins.elemAt sshYamls 0 ;
  _sshYamls = builtins.trace eee sshYamls;

  # # Generate sops secrets and etc entries dynamically
  # sshSecrets = lib.listToAttrs (map (name:
  #   # map name: let
  #   let
  #     filePath = lib.toString (sshDir + "/" + name);
  #     targetRel = lib.strings.dropSuffix ".yaml" name;
  #     targetPath = "/home/${hostCfg.username}/.ssh/" + targetRel;
  #   in {
  #     name = name;
  #     value = {
  #       sopsFile = filePath;
  #       path     = targetPath;
  #     };
  #   } _sshYamls
  # ));

  sshSecrets = lib.listToAttrs (
    builtins.map (name: let
      # filePath  = "${sshDir}/${name}";
      filePath  = sshDir + "/" + name;
      targetRel = lib.removeSuffix ".yaml" name;
      # targetPath = "/home/${config.users.users.hostUser.name}/.ssh/${targetRel}";
      targetPath = "/home/${hostCfg.username}/.ssh/" + targetRel;
      fileBaseName = lib.strings.splitString "." targetRel ;
      _name  = "ssh/" + targetRel ;
    in {
      # name  = "ssh-" + lib.replaceStrings ["/" "."] ["-" "-"] targetRel;
      # name  = "data" ;
      # name  = "ssh/" + builtins.elemAt (lib.reverseList fileBaseName) 0 ;
      name = builtins.trace _name _name;
      value = {
        # neededForUsers = true;
        # sopsFile = builtins.trace filePath filePath;
        sopsFile = filePath;
        # path = "/tmp/" ;
        # path     = targetPath;
        # path = "/persist/" + _name;
        # valueKey  = "data";
        key = "data";
      };
    }) _sshYamls
  );

  # value.sopsFile = ./secrets + "/wifi-${name}.sops.yaml";
  generatedWifiSopsSecret = builtins.listToAttrs (map (name: {
    name = "wifi/${name}";
    value = {};
  }) config.hostCfg.network.wifiNames );
in {



  # sops.templates."wifi-env".path = "/etc/wifi-secrets/all.env";
  # sops.templates."wifi-env".mode = "0600";
  # sops.templates."wifi-env".user = "root";
  # sops.templates."wifi-env".group = "root";
  # sops.templates."wifi-env".content =
  #   lib.concatStringsSep "\n" (map (name:
  #     ''WIFI_${upperCase name}="${config.sops.placeholder."wifi/${name}"}"''
  #   ) wifiList);


  # sops.templates."wifi-env" = {
  #   # path = "/etc/wifi-secrets/all.env";
  #   mode = "0600";
  #   # user = "root";
  #   # group = "root";
  #   content = lib.concatStringsSep "\n" (map (name:
  #     ''WIFI_${lib.strings.toUpper name}="${config.sops.secrets."wifi/${name}"}"''
  #   ) config.hostCfg.network.wifiNames );
  # };

  # sops.templates."wifi.env".content = lib.concatStringsSep "\n" (map (name:
  #   ''WIFI_${lib.strings.toUpper name}="${config.sops.placeholder."wifi/${name}"}"''
  # ) config.hostCfg.network.wifiNames );

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.hostname}.yaml";
    # validateSopsFiles = true;

    age.keyFile = "/tmp/keys.txt";

    secrets = lib.mkMerge [
    # Any fixed secrets (e.g., from this module or other custom ones)
    {

      root = { neededForUsers = true; };

      ${hostCfg.username} = { neededForUsers = true; };

    }

    sshSecrets
    generatedWifiSopsSecret

    ];

    templates."wifi.env".content = lib.concatStringsSep "\n" (map (name:
      ''WIFI_${lib.strings.toUpper name}="${config.sops.placeholder."wifi/${name}"}"''
    ) config.hostCfg.network.wifiNames );

  };

  systemd.tmpfiles.rules = lib.mkForce [
    "d /backup 0755 ${hostCfg.username}:users -"
  ];

  system.activationScripts.deploySshConfigs =
  let
    sshFolder = "/home/${hostCfg.username}/.ssh" ;
    secretSshFolderPath = lib.removeSuffix "config" config.sops.secrets."ssh/config".path ;
  in
  {
    text = ''
      if [[ -d ${sshFolder} ]] ; then
        cp -r ${sshFolder} /backup/ssh_$(date +"%Y_%m_%d__%H_%M_%S")
      fi
      cp -r ${secretSshFolderPath} ${sshFolder}
      chown -R ${hostCfg.username}:users ${sshFolder}
      chmod 700 ${sshFolder}
      find ${sshFolder} -type f -exec chmod 600 {} +
    '';
    deps = [ "setupSecrets" ];
  };

  # # Deploy decrypted files to ~/.ssh
  # environment.etc =  lib.listToAttrs (
  #   builtins.map (name: let
  #     destRel = lib.removeSuffix ".yaml" name;
  #     # destRel = lib.strings.dropSuffix ".yaml" rel;
  #     # dest    = "/home/" + config.users.users.hostUser.name + "/.ssh/" + destRel;
  #     dest = "/home/${hostCfg.username}/.ssh/" + destRel;
  #     # key     = lib.replaceStrings ["/" "."] ["-" "-"] destRel;
  #     key     = "ssh/" + destRel ;
  #   in {
  #     name = dest;
  #     value = {
  #       source = config.sops.secrets."${key}".path;
  #       mode   = "0600";
  #       user   = config.users.users.${hostCfg.username}.name;
  #       group  = config.users.users.${hostCfg.username}.group;
  #     };
  #   }) _sshYamls
  # );

}
