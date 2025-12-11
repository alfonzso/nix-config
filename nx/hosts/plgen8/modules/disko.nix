{ pkgs, ... }:
let
  zfsCommon = {
    atime = "off";
    compression = "lz4";
  };
  vbDisks = {
    root = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB1186e23e-adb5874c";
    hdd1 = "/dev/disk/by-id/ata-VBOX_HARDDISK_VBe9893aaa-41c6b093";
    hdd2 = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB18421013-462a44a1";
    ssd0 = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB0921d2c6-f8aeae52";
  };
in {

  networking.hostId =
    "04bf88b0"; # Generate with: head -c4 /dev/urandom | od -A none -t x4

  environment.systemPackages = with pkgs; [ zfs ];

  disko.rootMountPoint = "/mnt";

  # Define physical disks and their partitions
  disko.devices = {
    disk = {
      # HDD 1 (2TiB) - split 50%/50%
      hdd1 = {
        type = "disk";
        device = vbDisks.hdd1;
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              # size = "1T";  # First 1TB (adjust based on your actual disk size)
              size = "25G"; # First 1TB (adjust based on your actual disk size)
              name = "mirror";
              content = {
                type = "zfs";
                pool = "securepool";
              };
            };
            stripe = {
              size = "100%"; # Remaining space (should be ~1TB)
              name = "stripe";
              content = {
                type = "zfs";
                pool = "fastpool";
              };
            };
          };
        };
      };

      # HDD 2 (2TiB) - split 50%/50%
      hdd2 = {
        type = "disk";
        device = vbDisks.hdd2;
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              # size = "1T";  # First 1TB (adjust based on your actual disk size)
              size = "25G"; # First 1TB (adjust based on your actual disk size)
              name = "mirror";
              content = {
                type = "zfs";
                pool = "securepool";
              };
            };
            stripe = {
              size = "100%"; # Remaining space (should be ~1TB)
              name = "stripe";
              content = {
                type = "zfs";
                pool = "fastpool";
              };
            };
          };
        };
      };

      # SSD used as L2ARC cache
      ssdcache = {
        type = "disk";
        device = vbDisks.ssd0;
        content = {
          type = "gpt";
          partitions = {
            cache = {
              size = "100%";
              name = "cache";
              content = {
                type = "zfs";
                pool = "fastpool";
              };
            };
          };
        };
      };

      # Root SSD (single device rpool)
      ssdroot = {
        type = "disk";
        device = vbDisks.root;
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "512M";
              type = "EF00";
              name = "boot";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfsroot = {
              size = "100%";
              name = "zfsroot";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    # Define ZFS pools
    zpool = {
      # securepool: mirror of the two 'mirror' partitions (1TiB usable)
      securepool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = zfsCommon // {
          # ashift = "12";
          mountpoint = "none";
        };
        options = { ashift = "12"; };

        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "/mnt/secure";
            options = zfsCommon // { mountpoint = "legacy"; };
          };
        };
      };

      # fastpool: striped (raid0) across two stripe partitions + SSD L2ARC
      fastpool = {
        type = "zpool";
        # For stripe, just list the devices without mode - ZFS will stripe automatically
        rootFsOptions = zfsCommon // {
          # ashift = "12";
          mountpoint = "none";
        };
        options = { ashift = "12"; };

        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "/mnt/fast";
            options = zfsCommon // { mountpoint = "legacy"; };
          };
        };
      };

      # rpool: ZFS root pool on ssdroot
      rpool = {
        type = "zpool";
        rootFsOptions = zfsCommon // {
          # ashift = "12";
          mountpoint = "none";
        };
        options = { ashift = "12"; };

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options = zfsCommon;
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = zfsCommon;
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = zfsCommon;
          };
        };
      };
    };
  };
}
