{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ../../../nx/hosts/busanas
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.availableKernelModules = lib.mkForce [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "sd_mod"
      "ext4"
    ];
    kernelParams = lib.mkForce [
      "boot.shell_on_fail"
      "console=ttyS0"
    ];
    loader.efi.canTouchEfiVariables = lib.mkForce false;
  };

  hardware.firmware = lib.mkForce [ ];
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

  home-manager.users.${config.hostCfg.username}.systemd.user.services.sunshine.Install.WantedBy =
    lib.mkForce
      [ ];
}
