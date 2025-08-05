# {
#   disk = {
#     main = {
#       # device = "/dev/sdb";
#       device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0XB06332K";
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

{
  disk = {
    main = {
      type    = "disk";
      device = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0XB06332K";
      # content = {
      #   type       = "gpt";
      #   partitions = {
      #     ESP = {
      #       size = "500M";
      #       type = "EF00";
      #       content = {
      #         type         = "filesystem";
      #         format       = "vfat";
      #         mountpoint   = "/boot";
      #         mountOptions = [ "umask=0077" ];
      #       };
      #     };
      #     primary = {
      #       size = "100%";
      #       content = {
      #         type = "lvm_pv";
      #         vg   = "mainpool";
      #       };
      #     };
      #   };
      # };
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "mainpool";
            };
          };
        };
      };
    };
  };
  lvm_vg = {
    mainpool = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "200G";
          content = {
            type         = "filesystem";
            format       = "ext4";
            mountpoint   = "/";
            mountOptions = [ "defaults" ];
          };
        };
        home = {
          size = "150G";
          content = {
            type       = "filesystem";
            format     = "ext4";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
