{
  inputs,
  config,
  pkgs,
  lib,
  ProjectRoot,
  HostName,
  # hostCfg,
  ...
}:
let
  _mods        =  ProjectRoot + "/nx/modules" ;
  # hostCfg      = builtins.trace "---> ${config.hostCfg}" config.hostCfg ;
  hostCfg      = config.hostCfg ;
  # hostCfg      = config.hostCfg ;
  # nixSecrets   = builtins.toString inputs.nix-secrets ;
  # hostCfg = builtins.trace (builtins.toJSON config.hostCfg) ;
  # lel = builtins.trace "Value of myAttr: ${builtins.toJSON hostCfg}" hostCfg ;
  # var = builtins.trace "---> ${hostCfg.domain}" HostName ;
  # var = builtins.trace "---> ${hostCfg.domain}" HostName ;
  # kek = "";
  # _ = builtins.trace
  #   ( "HOSTCFG = " + toString config.hostCfg )
  #   config.hostCfg;
in
# ( var )
# builtins.seq (lib.debug.showVal hostCfg)
{
  # HostCfg.username = var ;


  imports = lib.flatten [
    ./hm

    ./config.nix
    ./hardware-configuration.nix
    ./mounts.nix
    ./mergerfs.nix
    ./samba.nix

    # no desktop for servers
    # "${_mods}/desktop/gnome.gdm.nix"

    "${_mods}/_sops.nix"
    "${_mods}/_ssh.nix"
    "${_mods}/_networking.nix"
    "${_mods}/_user.nix"
  ];

  # options.nixSecrets = lib.mkOption {
  #   type    = lib.types.str;
  #   default = hostCfg ;  
  # };

  # ( builtins.trace "foo" "bar" ) ;

  config = {
    # asdf = var ;
    # kek =  lel ;

    system.stateVersion = "25.05";

    hardware.enableRedistributableFirmware = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    # nix.settings.trusted-public-keys = [
    #   "nas:owUPp8g4dg7pKBKQAqcB48gEYkZFAyw12IfpGDBEeeY="
    # ];

    # nix = {
    #   requireSignedBinaryCaches = false;
    #   extraOptions = ''
    #     require-sigs = false
    #   '';
    # };

    # nix.settings.require-sigs = false;

    environment.systemPackages = with pkgs; [
      openssh
      bash-completion
      gcc
    ];

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

  };
}
