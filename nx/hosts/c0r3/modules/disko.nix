{ DiskoTesting, ... }:
let
  test = {
    storage = {
      diskById = "/dev/vdb";
      nixSize = "300G";
    };
  };

  prod = {
    storage = {
      # Replace this with the real 1TB disk before running disko.
      # Example command on the live installer: ls -l /dev/disk/by-id/
      diskById = "/dev/disk/by-id/ata-WDC_WD10EZEX-08WN4A0_WD-WCC6Y6VTAXF5";
      nixSize = "300G";
    };
  };

  myDevice = if DiskoTesting then test else prod;
in {
  disko.devices = {
    disk.storage = {
      type = "disk";
      device = myDevice.storage.diskById;

      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          nix = {
            size = myDevice.storage.nixSize;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [ "defaults" "noatime" ];
            };
          };

          games = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/games";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
