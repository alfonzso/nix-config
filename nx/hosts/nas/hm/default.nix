{ config, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs";
in {
  home-manager = {
    users.${hostCfg.username} = {

      imports =
        [ ./systemdUser/clone_my_stuff.nix "${_hm_programs}" ./packages.nix ];
      home = { stateVersion = "25.05"; };
    };
  };

}
