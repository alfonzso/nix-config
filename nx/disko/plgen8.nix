# {
#   disk = {
#     main = {
#       # device = "/dev/sdb";
#       device = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB1186e23e-adb5874c";
#       type = "disk";
#       content = {
#         type = "gpt";
#         partitions = {
#           boot = {
#             size = "1M";
#             type = "EF02"; # for BIOS boot
#           };
#           root = {
#             size = "100%";
#             content = {
#               type = "lvm_pv";
#               vg = "pool";
#             };
#           };
#         };
#       };
#     };
#   };
#   lvm_vg = {
#     pool = {
#       type = "lvm_vg";
#       lvs = {
#         root = {
#           size = "100%FREE";
#           content = {
#             type = "filesystem";
#             format = "ext4";
#             mountpoint = "/";
#           };
#         };
#       };
#     };
#   };
# }

{ pkgs, lib, ... }:

let
  # common ZFS dataset options
  zfsCommon = { atime = "off"; };

in {
  # Enable disko module

  disko = {
    devices = {

      # SSD root disk
      ssdroot = {
        type = "disk";
        device = "/dev/disk/by-id/DUMMY-SSD-ROOT"; # REPLACE
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "512MiB";
              type = "efi";
            };
            zfsroot = {
              size = "100%";
              type = "zfs";
            };
          };
        };
      };

      # ZFS root pool for NixOS
      rpool = {
        type = "zpool";
        mode = "single"; # single device pool
        mountpoint = "/";
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
        devices = [ "ssdroot:zfsroot" ];
      };

      # HDD 1
      hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/DUMMY-HDD1";
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              size = "50%";
              type = "zfs";
            };
            stripe = {
              size = "50%";
              type = "zfs";
            };
          };
        };
      };

      # HDD 2
      hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/DUMMY-HDD2";
        content = {
          type = "gpt";
          partitions = {
            mirror = {
              size = "50%";
              type = "zfs";
            };
            stripe = {
              size = "50%";
              type = "zfs";
            };
          };
        };
      };

      # SSD for L2ARC cache
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/DUMMY-SSD";
        content = {
          type = "gpt";
          partitions = {
            cache = {
              size = "100%";
              type = "zfs";
            };
          };
        };
      };

      # Secure ZFS pool (mirror)
      securepool = {
        type = "zpool";
        mode = "mirror";
        mountpoint = "/secure";
        options = { ashift = "12"; };
        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "/secure";
            options = lib.mkMerge [ zfsCommon { compression = "lz4"; } ];
          };
        };
        devices = [ "hdd1:mirror" "hdd2:mirror" ];
      };

      # Fast ZFS pool (stripe) with SSD cache
      fastpool = {
        type = "zpool";
        mode = "raid0"; # stripe
        mountpoint = "/fast";
        options = { ashift = "12"; };
        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "/fast";
            options = zfsCommon;
          };
        };
        devices = [ "hdd1:stripe" "hdd2:stripe" ];
        cache = [ "ssd:cache" ]; # SSD used as L2ARC
      };

    };
  };
}
