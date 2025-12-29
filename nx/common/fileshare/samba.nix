{ config, pkgs, ... }: {

  # Enable Samba service
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
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
      };

      # Private share (requires authentication)
      storage = {
        path = "/storage";
        browseable = "yes";
        writable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "${config.hostCfg.nasUser}";
        "write list" = "${config.hostCfg.nasUser}";
        "create mask" = "0755";
        "directory mask" = "0755";
      };

      transmission = {
        path = "/storage/media/transmission_downloads";
        browseable = "yes";
        writable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "${config.hostCfg.nasUser}";
        "write list" = "${config.hostCfg.nasUser}";
        "create mask" = "0755";
        "directory mask" = "0755";
      };
    };
  };

  # Add Samba user and set password
  system.activationScripts.sambaPasswords = let
    samba = config.services.samba.package;
    user = config.hostCfg.nasUser;
    pass = config.sops.secrets.samba_user_pwd.path;
  in {
    text = ''
      set -e
      pass_to_shell=$(cat ${pass})
      echo "#################################"
      echo "Setting Samba passwords..."
      echo "#################################"
      printf "$pass_to_shell\n$pass_to_shell\n" | ${samba}/bin/smbpasswd -a -s ${user}
    '';
    deps = [ "users" "groups" ];
  };

  # Create share directories with correct permissions
  # system.activationScripts.sambaDirs = let
  #   user = config.hostCfg.nasUser;
  # in {
  #   text = ''
  #     torrent=/storage/media/transmission_downloads
  #     if [[ ! -d $torrent ]] ; then
  #       mkdir -p $torrent
  #     fi
  #     chown -R ${user}:nasusers /mnt/disk00*
  #     chmod 0770 /mnt/disk00*
  #   '';
  # };
}
