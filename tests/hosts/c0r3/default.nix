{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ../../../nx/hosts/future-c0r3
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.availableKernelModules = lib.mkForce [
      "ata_piix"
      "sd_mod"
      "sr_mod"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
    ];
    kernelParams = lib.mkForce [
      "boot.shell_on_fail"
      "console=ttyS0"
    ];
    loader.efi.canTouchEfiVariables = lib.mkForce false;
  };

  hardware = {
    firmware = lib.mkForce [ ];
    nvidia.powerManagement.enable = lib.mkForce false;
  };

  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

  home-manager.users.${config.hostCfg.username}.systemd.user.services.sunshine.Install.WantedBy =
    lib.mkForce
      [ ];
}
