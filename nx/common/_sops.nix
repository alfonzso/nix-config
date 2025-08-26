{ pkgs, inputs, config, lib, NixSecrets, ProjectRoot, ... }:
let
  diffFiles = ProjectRoot + "/nx/common/scripts/diff_files.sh";
  nxLib = ProjectRoot + "/nx/lib";
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;

  personalDir = NixSecrets + "/personal";
  personalSSHDir = personalDir + "/ssh";

in  {

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
