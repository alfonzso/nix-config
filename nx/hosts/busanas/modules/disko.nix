{ DiskoTesting, ... }:
let
  devices =
    if DiskoTesting then
      {
        system = "/dev/disk/by-id/virtio-busanas-test-system";
        media = "/dev/disk/by-id/virtio-busanas-test-media";
      }
    else
      {
        system = "/dev/disk/by-id/nvme-BC511_NVMe_SK_hynix_256GB_CJ9CN62121070CI4A";
        media = "/dev/disk/by-id/wwn-0x500a0751e9b5fc5e";
      };
in
{
  disko.devices.disk = {
    system = {
      type = "disk";
      device = devices.system;
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
            size = "100%";
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
        };
      };
    };

    media = {
      type = "disk";
      device = devices.media;
      content = {
        type = "gpt";
        partitions.media = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/srv/media";
            mountOptions = [
              "defaults"
              "nofail"
              "noatime"
              "x-systemd.device-timeout=10s"
            ];
          };
        };
      };
    };
  };
}
