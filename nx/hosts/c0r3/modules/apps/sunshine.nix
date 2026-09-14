{ pkgs, ... }:
let
  sunshineSettings = {
    # KWin/PipeWire capture can stop producing video frames while audio and
    # input continue. KMS avoids that capture path.
    capture = "kms";
  };
in
{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
    settings = sunshineSettings;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
  };
}
