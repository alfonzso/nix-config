{ DiskoTesting, ... }:
let
  test = {
    main = {
      diskById = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB1186e23e-adb5874c";
      root.size = "25G";
      home.size = "15G";
    };
  };

  prod = {
    main = {
      diskById =
        "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0XB06332K";
      root.size = "200G";
      home.size = "150G";
    };
  };

  myDevice = { main = if DiskoTesting then test.main else prod.main; };

in {
  disko.rootMountPoint = "/mnt";
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = myDevice.main.diskById;
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
            # size = "200G";
            size = myDevice.main.root.size;
            # size = "20G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
          home = {
            # size = "150G";
            # size = "1G";
            size = myDevice.main.home.size;
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
