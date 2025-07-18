{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ mergerfs ];

  fileSystems."/mnt/storage" = {
    fsType = "fuse.mergerfs";
    device = "/mnt/disk00*";
    options = [
      "allow_other"
      "cache.attr=30"
      "cache.entry=5"
      "cache.files=auto-full"
      "cache.negative_entry=5"
      "cache.open=30"
      "cache.readdir=true"
      "cache.statfs=30"
      "cache.symlinks=true"
      "cache.writeback=true"
      "category.create=pfrd"
      "defaults"
      "dropcacheonclose=true"
      "fsname=mergerfs"
      "inodecalc=path-hash"
      "minfreespace=1G"
      "moveonenospc=true"
      "noforget"
      "nonempty"
      "use_ino"
    ];
  };



  # Optional: Configure systemd service to uncach files (requires python and aiofiles)
  # systemd.services.mergerfs-uncache = {
  #   path = [ (pkgs.python3.withPackages (ps: with ps; [ aiofiles ])) ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "/path/to/mergerfs-uncache.py -s /mnt/cache -d /mnt/mergerfs_slow -a 90 -t 90";
  #   };
  #   startAt = "Sat 00:00:00";
  # };
}
