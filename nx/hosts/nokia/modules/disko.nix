{ DiskoTesting, ... }:
let

  test = {
    root = {
      diskById = "/dev/vda";

      rootSize = "45G";
      homeSize = "45G";
    };
  };

  prod = {
    root = {
      diskById =
        "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S1ANNSAF414709B";
      rootSize = "100G";
      homeSize = "100G";
    };
  };

  myDevice = { root = if DiskoTesting then test.root else prod.root; };

in {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = myDevice.root.diskById;

      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";

              content = {
                type = "lvm_pv";
                vg = "vg0";
              };
            };
          };
        };
      };
    };

    lvm_vg.vg0 = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = myDevice.root.rootSize;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };

        home = {
          size = myDevice.root.homeSize;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
