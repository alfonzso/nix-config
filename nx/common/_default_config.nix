{
  inputs, config, pkgs, lib, ...
}:
{

  config = {

    hardware.enableRedistributableFirmware = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    environment.systemPackages = with pkgs; [
      openssh
      bash-completion
      gcc
      trash-cli
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
