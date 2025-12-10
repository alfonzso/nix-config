{ inputs, config, pkgs, lib, ... }: {

  config = {

    hardware.enableRedistributableFirmware = true;

    # time related configs
    time.timeZone = "Europe/Budapest";
    services.timesyncd.enable = true;

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

    fonts.packages = with pkgs; [ nerd-fonts.hack ];

    environment.systemPackages = with pkgs; [

      lua-language-server
      stylua

      rsync
      openssh
      bash-completion
      gcc
      cargo
      cmake
      gnumake
      fzf
      trash-cli
      wl-clipboard

      restic
      wireguard-tools

    ];

  };
}
