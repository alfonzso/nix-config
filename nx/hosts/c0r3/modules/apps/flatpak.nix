{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.bambulab.BambuStudio"
    ];
    # Keep Flatpak's NVIDIA GL extension aligned with the host driver.
    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };
}
