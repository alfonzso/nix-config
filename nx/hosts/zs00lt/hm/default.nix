{
  config,
  lib,
  pkgs,
  hostCfg,
  ...
}:
let
 homeDir = "/home/${hostCfg.username}" ;
 vimTMP  = "${homeDir}/.vim-tmp" ;
in
{
  imports = [
    ./programs
    ./packages.nix
  ];

  home = {

    activation.createCustomDir = lib.mkAfter ''
      mkdir -p ${vimTMP} || true
      chmod u+rw ${vimTMP}
    '';

    # This needs to actually be set to your username
    username = hostCfg.username ;
    homeDirectory = homeDir ;
    # You do not need to change this if you're reading this in the future.
    # Don't ever change this after the first build.  Don't ask questions.
    stateVersion = "24.11";
  };

  home.sessionVariables = {
    POETRY_VIRTUALENVS_IN_PROJECT = "true";
  }; 

  # With nixOS and hm, it wont be intalled,
  # use instead: nixos-rebuild switch --flake .#asdf
  # programs.home-manager.enable = true;

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

}
