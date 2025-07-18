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
}
