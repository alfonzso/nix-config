{
  config,
  pkgs,
  ...
}:
{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
    # settings.output_name = "Meta-0";
  };

  home-manager.users.${config.hostCfg.username} =
    { lib, ... }:
    {
      systemd.user.services.sunshine = {
        Unit = {
          Description = "Self-hosted game stream host for Moonlight";
          After = [
            "graphical-session.target"
            "pipewire.service"
            "pipewire-pulse.service"
            "wireplumber.service"
            "xdg-desktop-portal.service"
            "xdg-desktop-portal-gnome.service"
          ];
          Wants = [
            "graphical-session.target"
            "pipewire.service"
            "pipewire-pulse.service"
            "wireplumber.service"
            "xdg-desktop-portal.service"
            "xdg-desktop-portal-gnome.service"
          ];
          PartOf = [
            "graphical-session.target"
            "pipewire.service"
            "pipewire-pulse.service"
          ];
        };

        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
          ExecStart = "/run/wrappers/bin/sunshine";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };

      home.activation.ensureSunshineConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/sunshine"
      '';
    };
}
