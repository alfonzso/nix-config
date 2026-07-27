{
  config,
  lib,
  pkgs,
  ...
}:
let
  transmissionSettings = pkgs.writeText "busanas-transmission-settings.json" (
    builtins.toJSON {
      download-dir = "/srv/media";
      incomplete-dir = "/srv/media/incomplete";
      incomplete-dir-enabled = true;
      rpc-enabled = false;
      watch-dir = "/srv/media/watch";
      watch-dir-enabled = true;
    }
  );

  guardedTransmission = pkgs.symlinkJoin {
    name = "transmission-gtk-guarded";
    paths = [ pkgs.transmission_4-gtk ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/transmission-gtk" \
        --run '${pkgs.util-linux}/bin/mountpoint -q /srv/media || { echo "Refusing to start: /srv/media is not mounted" >&2; exit 1; }'
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    libva-utils
    lm_sensors
    pciutils
    smartmontools
    usbutils
  ];

  home-manager.users.${config.hostCfg.username} =
    { lib, ... }:
    {
      home.packages = [ guardedTransmission ];

      home.activation.seedTransmissionSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings_dir="$HOME/.config/transmission"
        settings_file="$settings_dir/settings.json"
        if [ ! -e "$settings_file" ]; then
          ${pkgs.coreutils}/bin/install -d -m 0700 "$settings_dir"
          ${pkgs.coreutils}/bin/install -m 0600 \
            ${transmissionSettings} "$settings_file"
        fi
      '';
    };
}
