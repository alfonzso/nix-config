{ pkgs, ... }: {
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.firmware = [ pkgs.edid-generator ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    branch = "legacy_580";
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
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
    # Force HDMI on with a generic 1080p EDID so headless streaming has a real mode.
    "drm.edid_firmware=HDMI-A-1:edid/1920x1080.bin"
    "video=HDMI-A-1:1920x1080@60e"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
}
