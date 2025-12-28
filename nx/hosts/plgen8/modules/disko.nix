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
        "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S1ANNSAF414709B";
    };
    hdd1 = {
      diskById = "/dev/disk/by-id/ata-WDC_WD20EFZX-68AWUN0_WD-WX12DB0DPS74";
      # mirror.size = "1T";
      mirror.size = "922G";
      # mirror.size = "50%";
    };
    hdd2 = {
      diskById = "/dev/disk/by-id/ata-WDC_WD20EFZX-68AWUN0_WD-WX22DB0AD5AP";
      # mirror.size = "1T";
      mirror.size = "922G";
      # mirror.size = "50%";
    };
    ssd0 = { diskById = "/dev/disk/by-id/ata-ADATA_SU800_2G4620087298"; };

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
              # name = "mirror";
              content = {
                type = "zfs";
                pool = "securepool";
              };
            };
            stripe = {
              size = "100%"; # Remaining space (should be ~1TB)
              # name = "stripe";
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
              # name = "mirror";
              content = {
                type = "zfs";
                pool = "securepool";
              };
            };
            stripe = {
              size = "100%"; # Remaining space (should be ~1TB)
              # name = "stripe";
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
            ##############
            # first (u)efi mode
            # biosboot and boot is for legacy (like gen8 only supports legacy)
            ##############
            # efi = {
            #   size = "512M";
            #   type = "EF00";
            #   name = "boot";
            #   content = {
            #     type = "filesystem";
            #     format = "vfat";
            #     mountpoint = "/boot";
            #   };
            # };
            biosboot = {
              size = "1M";
              type = "EF02"; # BIOS boot partition type
              name = "biosboot";
            };
            boot = {
              size = "512M";
              name = "boot";
              content = {
                type = "filesystem";
                format = "ext4"; # or ext2/ext3
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
        # mode = "mirror";
        mode = {
          topology = {
            type = "topology";
            vdev = [{
              mode = "mirror";
              members = [
                "/dev/disk/by-partlabel/disk-hdd1-mirror"
                "/dev/disk/by-partlabel/disk-hdd2-mirror"
              ];
            }];
          };
        };
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
          nix = { # Add nix here!
            type = "zfs_fs";
            mountpoint = "/nix";
            options = zfsCommon // { mountpoint = "legacy"; };
          };
        };
      };

      # fastpool: striped (raid0) across two stripe partitions + SSD L2ARC
      fastpool = {
        type = "zpool";
        # For stripe, just list the devices without mode - ZFS will stripe automatically
        mode = {
          topology = {
            type = "topology";
            vdev = [{
              mode = ""; # empty string = stripe
              members = [
                "/dev/disk/by-partlabel/disk-hdd1-stripe"
                "/dev/disk/by-partlabel/disk-hdd2-stripe"
              ];
            }];
            cache = [ "/dev/disk/by-partlabel/disk-ssdcache-cache" ];
          };
        };
        rootFsOptions = zfsCommon // { mountpoint = "none"; };
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
          # nix = {
          #   type = "zfs_fs";
          #   mountpoint = "/nix";
          #   options = zfsCommon;
          # };
        };
      };
    };
  };
}
