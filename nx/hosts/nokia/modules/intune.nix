{ pkgs, nixpkgsUnstable, ... }: {

  # disabledModules = [ "services/security/intune.nix" ];
  #
  # imports = [
  #   "${unstableInput}/nixos/modules/services/security/intune.nix"
  # ];

  # Keep the module enabled (PAM depends on it) but we override the service
  services.intune.enable = true;

  # users.users.microsoft-identity-broker = {
  #   group = "microsoft-identity-broker";
  #   isSystemUser = true;
  # };
  #
  # users.groups.microsoft-identity-broker = { };
  # # environment.systemPackages =
  # #   [ nixpkgsUnstable.microsoft-identity-broker nixpkgsUnstable.intune-portal ];
  # systemd.packages =
  #   [ nixpkgsUnstable.microsoft-identity-broker nixpkgsUnstable.intune-portal ];
  #
  # systemd.tmpfiles.packages = [ nixpkgsUnstable.intune-portal ];
  # services.dbus.packages = [ nixpkgsUnstable.microsoft-identity-broker ];

  xdg.portal.enable = true;

  # Keep main system stable
  environment.systemPackages = with pkgs; [
    microsoft-edge
    # install Intune from unstable
    # nixpkgsUnstable.intune-portal
    # nixpkgsUnstable.microsoft-identity-broker
  ];
}
