{ config, lib, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  _hm_programs = ProjectRoot + "/nx/common/hm_programs";

in {
  systemd.user.tmpfiles.rules =
    [ "d ${vimTMP} 0755 ${hostCfg.username} users -" ];

  home-manager = {
    extraSpecialArgs = { hostCfg = config.hostCfg; };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {

      programs.home-manager.enable = true;
      xdg.enable = true;

      home = {

        username = hostCfg.username;
        # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = lib.mkDefault "25.05";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

}
