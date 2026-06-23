{ config, ... }: {
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    # Enable later for full Steam/Wine 32-bit game compatibility.
    enable32Bit = false;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    powerManagement.enable = false;
  };

  boot.blacklistedKernelModules = [ "nouveau" ];
}
