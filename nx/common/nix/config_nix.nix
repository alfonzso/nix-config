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
        warn-dirty = false;
      };
    };

  };
}
