{
  config,
  inputs,
  ProjectRoot,
  ...
}:
let
  hostCfg = config.hostCfg;
  _common = ProjectRoot + "/nx/common";
in
{
  home-manager = {
    users.${hostCfg.username} = {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
        "${_common}/hm/systemdUser/clone_my_stuff.nix"
        "${_common}/hm_programs"
        ./packages.nix
        ./go.nix
      ];

      home = {
        stateVersion = "25.05";
      };
    };
  };
}
