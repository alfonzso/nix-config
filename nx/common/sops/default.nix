{
  config,
  lib,
  NixSecrets,
  pkgs,
  ...
}:
let
  sopsFolder = NixSecrets + "/sops";
  hostCfg = config.hostCfg;
  ageKeyFile = "/persist/sops/age/keys.txt";

in
{
  system.activationScripts.lockSopsAgeKey.text = ''
    key=${ageKeyFile}
    if [ -L "$key" ]; then
      echo "sops age key: refusing symlink $key" >&2
    elif [ -f "$key" ]; then
      if ! ${pkgs.coreutils}/bin/chown root:root "$key" \
        || ! ${pkgs.coreutils}/bin/chmod 0600 "$key"; then
        echo "sops age key: failed to secure $key" >&2
      fi
    fi

    for dir in /persist/sops /persist/sops/age; do
      if [ -L "$dir" ]; then
        echo "sops age key: refusing symlink $dir" >&2
      elif [ -d "$dir" ]; then
        if ! ${pkgs.coreutils}/bin/chown root:root "$dir" \
          || ! ${pkgs.coreutils}/bin/chmod 0700 "$dir"; then
          echo "sops age key: failed to secure $dir" >&2
        fi
      fi
    done
  '';

  sops.age.keyFile = ageKeyFile;

  sops = {

    defaultSopsFile = "${sopsFolder}/${hostCfg.currentConfigName}.yaml";

    secrets = lib.mkMerge [
      {
        root = {
          neededForUsers = true;
        };
        ${hostCfg.username} = {
          neededForUsers = true;
        };
      }
    ];

  };

}
