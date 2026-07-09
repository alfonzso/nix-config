{ pkgs, ... }:
let
  # Generated with https://edid.build/ using 1080p + LPCM audio support.
  c0r3AudioEdid = pkgs.runCommand "c0r3-1080p-audio-edid" { } ''
    mkdir -p "$out/lib/firmware/edid"
    cp ${../../firmware/edid/1920x1080-audio.bin} "$out/lib/firmware/edid/1920x1080-audio.bin"
  '';
in
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.firmware = [
    pkgs.edid-generator
    c0r3AudioEdid
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    branch = "legacy_580";
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Force the NVIDIA Vulkan ICD for native and 32-bit Steam/Proton games.
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json";
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    # Force HDMI on with an audio-capable 1080p EDID so local monitor-jack
    # audio and headless Sunshine can use the same connector.
    "drm.edid_firmware=HDMI-A-1:edid/1920x1080-audio.bin"
    "video=HDMI-A-1:1920x1080@60e"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
}
