{ config, lib, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  # sambaPassPath = config.sops.secrets.samba_user_pwd.path;
  ProjectRoot = config.hostCfg.root;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs";

in {
  home-manager = {
    extraSpecialArgs = { hostCfg = config.hostCfg; };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {

      imports = [ "${_hm_programs}" ./packages.nix ];
      home = {

        activation.createCustomDir = lib.mkAfter ''
          mkdir -p ${vimTMP} || true
          chmod u+rw ${vimTMP}
        '';

        username = hostCfg.username;
        # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = "25.05";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

}
