{
  config,
  lib,
  pkgs,
  ...
}:
let
  sunshineSettings = {
    capture = "kms";
    encoder = "vaapi";
  };
  sunshineConfig = (pkgs.formats.keyValue { }).generate "sunshine.conf" sunshineSettings;
in
{
  hardware = {
    uinput.enable = true;
    graphics.extraPackages = [ pkgs.intel-media-driver ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = false;
    package = pkgs.sunshine;
    settings = sunshineSettings;
  };

  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.0/24 tcp dport { 47984, 47989, 47990, 48010 } accept
    ip saddr 192.168.1.0/24 udp dport { 47998-48000, 48002, 48010 } accept
  '';

  home-manager.users.${config.hostCfg.username} =
    { lib, ... }:
    {
      systemd.user.services.sunshine = {
        Unit = {
          Description = "Sunshine game-streaming host";
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
            "wireplumber.service"
            "xdg-desktop-portal.service"
            "xdg-desktop-portal-gnome.service"
          ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
          ExecStart = "/run/wrappers/bin/sunshine ${sunshineConfig}";
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
