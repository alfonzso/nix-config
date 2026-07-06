{ pkgs, lib, ... }: {

  config = {
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than +15";
      };
      package = lib.mkDefault pkgs.nix;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        download-buffer-size = 536870912;
        auto-optimise-store = true;
        warn-dirty = false;
      };
    };

  };
}
