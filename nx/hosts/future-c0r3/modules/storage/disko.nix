{ DiskoTesting, ... }:
let
  test = {
    storage = {
      ssdById = "/dev/disk/by-id/virtio-c0r3-test-ssd";
      hddById = "/dev/disk/by-id/virtio-c0r3-test-hdd";
    };
  };

  prod = {
    storage = {
      ssdById = "/dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PYNL0TB43063B";
      hddById = "/dev/disk/by-id/ata-WDC_WD10EZEX-08WN4A0_WD-WCC6Y6VTAXF5";
    };
  };

  myDevice = if DiskoTesting then test else prod;
in
{
  disko.devices = {
    disk.ssd = {
      type = "disk";
      device = myDevice.storage.ssdById;

      content = {
        type = "gpt";
        partitions = {
          esp = {
            priority = 1;
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          root = {
            priority = 2;
            name = "root";
            size = "350G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };

          home = {
            priority = 3;
            name = "home";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
        };
      };
    };

    disk.hdd = {
      type = "disk";
      device = myDevice.storage.hddById;

      content = {
        type = "gpt";
        partitions = {
          games = {
            name = "games";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/games";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
