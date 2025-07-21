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
    in {
      # name  = "ssh-" + lib.replaceStrings ["/" "."] ["-" "-"] targetRel;
      # name  = "data" ;
      # name  = "ssh/" + builtins.elemAt (lib.reverseList fileBaseName) 0 ;
      name  = "ssh/" + targetRel ;
      value = {
        sopsFile = filePath;
        # path     = targetPath;
        # valueKey  = "data";
        key = "data";
      };
    }) _sshYamls
  );

in {

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.hostname}.yaml";
    # validateSopsFiles = true;

    age.keyFile = "/tmp/keys.txt";

    secrets = {

      root = { neededForUsers = true; };

      ${hostCfg.username} = { neededForUsers = true; };

      # samba_user_pwd = { owner = "${hostCfg.username}"; };
      #
      # "samba/user/name" = { };
      # "samba/user/password" = { };

      # TODO: needed auto default secret from sops ?
      # "wifi/house"  = {} ;
      # "wifi/house5" = {} ;
    } // sshSecrets ;

  };


  system.activationScripts.deploySshConfigs =
  let
    sshFolder = "/home/${hostCfg.username}/.ssh" ;
  in
  {
    text = ''
      cp -r /run/secrets/ssh ${sshFolder}
      chown -R ${hostCfg.username}:users ${sshFolder}
      chmod 700 ${sshFolder}
      find ${sshFolder} -type f -exec chmod 600 {} +
      # chown -R nxadmin:users /home/nxadmin/.ssh
      # chmod 700 /home/nxadmin/.ssh
      # find /home/nxadmin/.ssh -type f -exec chmod 600 {} +
    '';
    # deps = [ config.sops ];
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
