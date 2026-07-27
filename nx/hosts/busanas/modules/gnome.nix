{
  config,
  pkgs,
  ProjectRoot,
  ...
}:
let
  username = config.hostCfg.username;
  # busanasEdid = pkgs.runCommand "busanas-1080p-audio-edid" { } ''
  #   mkdir -p "$out/lib/firmware/edid"
  #   cp ${../../c0r3/firmware/edid/1920x1080-audio.bin} \
  #     "$out/lib/firmware/edid/1920x1080-audio.bin"
  # '';
in
{
  imports = [ (ProjectRoot + "/nx/desktop/gnome.gdm.nix") ];

  console.keyMap = "hu";
  services.xserver.xkb.layout = "hu,us";

  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };

  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
    suspend-then-hibernate.enable = false;
  };

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;

  # hardware.firmware = [ busanasEdid ];
  # boot.kernelParams = [
  #   "drm.edid_firmware=HDMI-A-1:edid/1920x1080-audio.bin"
  #   "video=HDMI-A-1:1920x1080@60e"
  # ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      dconf = {
        enable = true;
        settings = {
          "org/gnome/desktop/input-sources".sources = [
            (lib.hm.gvariant.mkTuple [
              "xkb"
              "hu"
            ])
            (lib.hm.gvariant.mkTuple [
              "xkb"
              "us"
            ])
          ];
          "org/gnome/desktop/session".idle-delay = 0;
          "org/gnome/desktop/screensaver" = {
            idle-activation-enabled = false;
            lock-enabled = false;
          };
          "org/gnome/settings-daemon/plugins/power" = {
            idle-dim = false;
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-ac-timeout = 0;
            sleep-inactive-battery-type = "nothing";
            sleep-inactive-battery-timeout = 0;
          };
        };
      };
    };
}
