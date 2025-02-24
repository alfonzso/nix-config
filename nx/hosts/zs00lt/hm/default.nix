{
  config,
  lib,
  pkgs,
  hostCfg,
  ...
}:
let
  
in
{
  imports = [
    # ../hosts/${hostCfg.hostname} 
    ./packages.nix
  ];
  home = {
    # This needs to actually be set to your username
    username = hostCfg.username;
    homeDirectory = "/home/${hostCfg.username}";
    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "24.11";
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  programs.home-manager.enable = true;

}
