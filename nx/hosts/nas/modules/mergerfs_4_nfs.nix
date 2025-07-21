{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ mergerfs ];

  # fileSystems."/storage" = {
  fileSystems."/storage" = let
    # user = config.hostCfg.NASUser;
    userName = config.hostCfg.NASUser;
    uid = config.users.users.${userName}.uid;
    # disk = "disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
  in {
    device = "/mnt/disk00*";
    # device = lib.mkForce (
    #   # branches separated by ':'
    #   "/mnt/disk1:/mnt/disk2:/mnt/disk3:/mnt/disk4"
    # );
    fsType = "fuse.mergerfs";
    options = [
      "uid=${builtins.toString uid}"
      "gid=nasusers"

      # General FUSE options
      "defaults"
      "allow_other"

      # MergerFS-specific settings
      "fsname=mergerfs"
      "inodecalc=path-hash"
      "minfreespace=1G"
      "moveonenospc=true"
      "category.create=pfrd"
      "dropcacheonclose=true"
      "noforget"
      "nonempty"
      "use_ino"
      "func.getattr=newest"

      # Metadata caching tuned for NFS safety
      "cache.files=off"
      "attr_timeout=1"
      "entry_timeout=1"
      "cache.statfs=1"
    ];
  };
}
