{ config, pkgs, personal, ... }:

let
  # Define your Samba user and password (change these!)
  hostCfg = config.hostCfg;
  # sambaUser = personal.samba.user.name;
  # sambaUser.password = personal.samba.user.password;
  # sambaUser = config.sops.secrets.samba.user.path;
  # sambaUser = config.sops.secrets.samba.user.path;
  # sambaUser = config.sops.secrets.nxadmin.path;
  # sambaUser = config.sops.secrets."samba/user/name".path;
  # sambaUser = config.sops.secrets."samba/user";
  # sambaUser = config.sops.secrets."samba/user".value;
  # smb = config.sops.secrets."samba/user".value;
  # smb = config.sops.secrets."samba/user";
  # _sambaUser = {
  #   name =  config.sops.secrets."samba/user/name".path;
  #   password =  config.sops.secrets."samba/user/password".path;
  # } ;
  # sambaUser = builtins.trace _sambaUser.name _sambaUser ;

  # sambaNamePath = config.sops.secrets."samba/user/name".path;
  # sambaPassPath = config.sops.secrets."samba/user/password".path;

  sambaPassPath = config.sops.secrets.samba_user_pwd.path;
  # sambaUser = config.sops.secrets."${hostCfg.username}.samba.user".path;
  # sambaUser = "smbuser";
  # sambaUser.password = "your_secure_password_here";  # Change to a strong password
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
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        # "hosts allow" = "192.168.1. 127.0.0.1 localhost";
        # "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      } ;

      # shares = {
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
        writable = "yes" ;
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "${config.hostCfg.sambaUser}";
        "write list" = "${config.hostCfg.sambaUser}";
        "create mask" = "0755";
        "directory mask" = "0755";
      };
      # };
    };
  };

  # Create system users and groups
  users.groups.smbusers = {};
  
  users.users.${config.hostCfg.sambaUser} = {
    isNormalUser = true;
    group = "smbusers";
    extraGroups = [ "smbusers" ];
  };

  # Add Samba user and set password
  system.activationScripts.sambaPasswords = let
    samba = config.services.samba.package;
    user = config.hostCfg.sambaUser;
    pass = config.sops.secrets.samba_user_pwd.path;
  in {
    text = ''
      pass_to_shell=$(cat ${pass})
      echo "#################################"
      echo "Setting Samba passwords..."
      echo "#################################"
      printf "$pass_to_shell\n$pass_to_shell\n" | ${samba}/bin/smbpasswd -a -s ${user}
    '';
    deps = [ "users" "groups" ];
  };

  # Create share directories with correct permissions
  system.activationScripts.sambaDirs = let
    user = config.hostCfg.sambaUser;
    pass = config.sops.secrets.samba_user_pwd.path;
  in {
    text = ''
      chown -R ${user}:smbusers /mnt/disk00*
      chmod 0770 /mnt/disk00*
    '';
  };
}
