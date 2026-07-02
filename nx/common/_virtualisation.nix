{ config, pkgs, ... }:
{
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
  };
  users.users.${config.hostCfg.username} = {
    extraGroups = [ "podman" ];
  };

  environment.systemPackages = with pkgs; [ qemu ];

  # # User namespace configuration
  # boot.kernel.sysctl = {
  #   "user.max_user_namespaces" = 28633;
  # };
}
