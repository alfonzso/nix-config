{ config, pkgs, ... }: {
  # Required packages
  environment.systemPackages = [ pkgs.nfs-utils ];

  # Enable NFS server with recommended settings
  services.nfs.server = {
    enable = true;
    # Use fixed ports for better firewall control
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4003;

    # Recommended exports configuration
    exports = ''
      # /storage 192.168.1.0/24(rw,sync,no_subtree_check,fsid=0) 172.0.0.0/8(rw,sync,no_subtree_check,fsid=0)

      # Public read-only share example
      # /srv/public *(ro,insecure,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
      # ,anonuid=65534,anongid=65534
      # ,anonuid=65534,anongid=65534
      /storage 192.0.0.0/8(rw,sync,no_subtree_check,fsid=0,insecure)
      /storage 172.0.0.0/8(rw,sync,no_subtree_check,fsid=0,insecure)
    '';

    # Enable NFSv4 with Kerberos support
    extraNfsdConfig = ''
      [nfsd]
      vers4 = y
      vers3 = y

      # [gssd]
      # use-gss-proxy = 1
    '';
  };

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [
      2049 # NFS
      4001 # lockd
      4002 # mountd
      4003 # statd
      111 # rpcbind
    ];
    allowedUDPPorts = [ 2049 4001 111 ];
  };

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

  # # Security settings
  # services.rpcbind.enable = true;
  # services.idmapd.enable = true;

  # Performance tuning
  boot.kernel.sysctl = {
    "sunrpc.tcp_slot_table_entries" = 128;
    "sunrpc.udp_slot_table_entries" = 128;
    #   "fs.nfs.nfs_callback_tcpport" = 8765;  # Fixed callback port
  };

  # Optional: Kerberos configuration for secure NFS
  # security.krb5 = {
  #   enable = true;
  #   libdefaults.default_realm = "EXAMPLE.COM";
  #   domain_realm = {
  #     "example.com" = "EXAMPLE.COM";
  #     ".example.com" = "EXAMPLE.COM";
  #   };
  # };
}
