{
  home-manager,
  inputs,
  nixpkgs,
  sops-nix,
}:
flakeConfigName:
let
  hostFlakeConfigPath = ../nx/hosts/${flakeConfigName}/_flake_config.nix;
  hostFlakeConfig =
    if builtins.pathExists hostFlakeConfigPath then
      import hostFlakeConfigPath { inherit inputs; }
    else
      { };
  hostNixpkgs = hostFlakeConfig.nixpkgs or nixpkgs;
  hostHomeManager = hostFlakeConfig.home-manager or home-manager;
  hostSopsNix = hostFlakeConfig.sops-nix or sops-nix;
in
{
  nixpkgs = hostNixpkgs;
  homeManager = hostHomeManager;
  sopsNix = hostSopsNix;
  systemFunc = hostNixpkgs.lib.nixosSystem;
}
