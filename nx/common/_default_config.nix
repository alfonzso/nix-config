{
  inputs, config, pkgs, lib, ...
}:
{

  config = {

    hardware.enableRedistributableFirmware = true;

    hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
    General = {
    ControllerMode = "bredr"; # Fix frequent Bluetooth audio dropouts
    Experimental = true;
    FastConnectable = true;
    };
    Policy = {
    AutoEnable = true;
    };
    };
    };

    # time related configs
    time.timeZone = "Europe/Budapest";
    services.timesyncd.enable = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];

    fonts.packages = with pkgs; [ nerd-fonts.hack ];

    environment.systemPackages = with pkgs; [
      rsync
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
