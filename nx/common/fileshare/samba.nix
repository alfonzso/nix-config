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
    user = config.hostCfg.nasUser;
    pass = config.sops.secrets.samba_user_pwd.path;
    _PATH = with pkgs;
      "PATH=${lib.makeBinPath [ samba ]}:/run/current-system/sw/bin";
  in {
    text = ''
      set -e
      export PATH=$PATH:${_PATH}

      pass_to_shell=$(cat ${pass})
      echo "#################################"
      echo "Setting Samba passwords..."
      echo "#################################"

      # added || true cuz when installed with nx anywhere its fails and
      # breaks the whole install process
      printf "$pass_to_shell\n$pass_to_shell\n" | ${pkgs.samba}/bin/smbpasswd -a -s ${user} || true
    '';
    deps = [ "users" "groups" "setupSecrets" ];
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
