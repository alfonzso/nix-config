{ pkgs, ... }: {

  config = {

    hardware.enableRedistributableFirmware = true;

    # time related configs
    time.timeZone = "Europe/Budapest";
    services.timesyncd.enable = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

    fonts.packages = with pkgs; [ nerd-fonts.hack ];

  };
}
