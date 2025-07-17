{ config, pkgs, ... }:

let
  # Define your Samba user and password (change these!)
  hostCfg = config.hostCfg;
  # sambaUser = "smbuser";
  # sambaPassword = "your_secure_password_here";  # Change to a strong password
in {

  # Create system user for Samba access
  # users.users.${sambaUser} = {
  #   isNormalUser = true;
  #   group = "sambashare";
  #   extraGroups = [ "users" ];
  # };

  # Create dedicated group for Samba shares
  # users.groups.sambashare = {};

  # Enable Samba service
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = Samba Server
      netbios name = NIXOS
      security = user
      hosts allow = 192.168.1. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';
    
    shares = {
      # Public share (no authentication)
      # public = {
      #   path = "/srv/samba/public";
      #   browseable = "yes";
      #   "read only" = "no";
      #   "guest ok" = "yes";
      #   "create mask" = "0644";
      #   "directory mask" = "0755";
      # };
      
      # Private share (requires authentication)
      storage = {
        path = "/mnt/storage";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = hostCfg.username;
        "create mask" = "0755";
        "directory mask" = "0755";
      };
    };
  };

  # Create directories with correct permissions
  # systemd.tmpfiles.rules = [
  #   "d /srv/samba/public 0775 nobody users -"
  #   "d /srv/samba/private 0770 ${sambaUser} sambashare -"
  # ];

  # Add Samba user and set password
  system.activationScripts.sambaAddUser = ''
    if ! ${pkgs.samba}/bin/smbpasswd -e -L -s -a ${hostCfg.username} <<EOF
    ${sambaPassword}
    ${sambaPassword}
    EOF
    then
      echo "Failed to set Samba password"
      exit 1
    fi
  '';
}
