{ lib, NixSecrets, ProjectRoot, ... }:
let
  nxLib = ProjectRoot + "/nx/lib";
  personalDir = NixSecrets + "/personal";
  personalSSHDir = personalDir + "/ssh";

in {

  sops = {
    secrets = lib.mkMerge [
      (import "${nxLib}/_sops_ssh.nix" {
        inherit lib;
        sshDir = personalSSHDir;
      })
    ];
  };

}
