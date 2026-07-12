{ config, pkgs, ... }:
{
  virtualisation = {
    containers.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
    spiceUSBRedirection.enable = true;
  };
  programs.virt-manager.enable = true;

  users.users.${config.hostCfg.username} = {
    extraGroups = [ "kvm" "libvirtd" "podman" ];
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    qemu
    swtpm
    virt-viewer
    virtio-win
  ];

  # # User namespace configuration
  # boot.kernel.sysctl = {
  #   "user.max_user_namespaces" = 28633;
  # };
}
