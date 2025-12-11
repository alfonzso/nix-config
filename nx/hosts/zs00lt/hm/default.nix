# { config, ProjectRoot, ... }:
# let
#   hostCfg = config.hostCfg;
#   _hm_programs = ProjectRoot + "/nx/common/hm_programs";
# in {
#   home-manager = {
#     users.${hostCfg.username} = {
#
#       imports =
#         [ ./systemdUser/clone_my_stuff.nix "${_hm_programs}" ./packages.nix ];
#       home = { stateVersion = "24.11"; };
#     };
#   };
#
# }
{ config, ProjectRoot, ... }:
let
  hostCfg = config.hostCfg;
  _common = ProjectRoot + "/nx/common";
in {
  home-manager = {
    users.${hostCfg.username} = {

      imports = [
        "${_common}/hm/systemdUser/clone_my_stuff.nix"
        "${_common}/hm_programs"
        ./packages.nix
      ];
      home = { stateVersion = "24.11"; };
    };
  };

}
