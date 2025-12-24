{ config, pkgs, ... }: {

  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.hplipWithPlugin ];

  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip ];
  };

  programs.system-config-printer.enable = true;

  users.users.${config.hostCfg.username} = {
    extraGroups = [ "scanner" "lp" ];
  };
}
