{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device =
          "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0XB06332K";
        # device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
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
            # size = "20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
          home = {
            size = "150G";
            # size = "1G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };
        };
      };
    };
  };
}
