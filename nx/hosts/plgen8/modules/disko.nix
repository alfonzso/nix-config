{ pkgs, DiskoTesting, ... }:
let
  zfsCommon = {
    atime = "off";
    compression = "lz4";
  };

  test = {
    root = {
      diskById = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB1186e23e-adb5874c";
    };
    hdd1 = {
      diskById = "/dev/disk/by-id/ata-VBOX_HARDDISK_VBe9893aaa-41c6b093";
      mirror.size = "25G";
    };
    hdd2 = {
      diskById = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB18421013-462a44a1";
      mirror.size = "25G";
    };
    ssd0 = {
      diskById = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB0921d2c6-f8aeae52";
    };
  };

  prod = {
    root = {
      diskById =
        "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0XB06332K";
    };
    hdd1 = {
      diskById = "/dev/disk/by-id/..............";
      mirror.size = "1T";
    };
    hdd2 = {
      diskById = "/dev/disk/by-id/..............";
      mirror.size = "1T";
    };
    ssd0 = { diskById = "/dev/disk/by-id/................"; };

  };

  myDevice = {
    root = if DiskoTesting then test.root else prod.root;
    hdd1 = if DiskoTesting then test.hdd1 else prod.hdd1;
    hdd2 = if DiskoTesting then test.hdd2 else prod.hdd2;
    ssd0 = if DiskoTesting then test.ssd0 else prod.ssd0;
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
        device = myDevice.hdd1.diskById;
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              size = myDevice.hdd1.mirror.size;
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
        device = myDevice.hdd2.diskById;
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              size = myDevice.hdd2.mirror.size;
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
        device = myDevice.ssd0.diskById;
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
        device = myDevice.root.diskById;
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
