{ config, pkgs, lib, ... }:

let
  _disksUUID = config.hostCfg.storage.disksUUID ;
  indexedUUIDs = lib.zipLists (map toString (lib.range 1 (builtins.length _disksUUID))) _disksUUID;

  userName = config.hostCfg.NASUser;

in {
  fileSystems = lib.listToAttrs (map (pair:
    let
      idx = pair.fst;
      uuid = pair.snd;
    in {
      name = "/mnt/disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
      value = {
        device = "UUID=${uuid}";
        fsType = "ext4";
        # options = [
        # # "uid=${builtins.toString uid}"
        # # "gid=nasusers"
        # "fmask=113"
        # "dmask=002"
        # ];
      };
    }) indexedUUIDs);

  # systemd.requires = lib.listToAttrs (map (pair:
  #   let
  #     idx = pair.fst;
  #     uuid = pair.snd;
  #   in {
  #       "/mnt/disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
  #   }) indexedUUIDs);

  # systemd.requires = [ "mnt-disk001.mount" ];
  # systemd.requires = map (pair: 
  # let
  #   idx = pair.fst ;
  # in {
  #   name = "/mnt/disk${lib.strings.fixedWidthString 3 "0" (toString idx)}"  ;
  # }) indexedUUIDs;

  systemd.services = builtins.listToAttrs (
    map (pair:
    let
      idx = pair.fst ;
      # disk = "/mnt/disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
      disk = "disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
    in {
      # enable = true;
      # name = "mnt-disk${lib.strings.fixedWidthString 3 "0" (toString idx)}" ;
      # value = {
      #   script = "echo ${idx}";
      # };

      name = disk ; 
      # name = "mnt-disk${lib.strings.fixedWidthString 3 "0" (toString idx)}";
      value = {

        enable = true;
        description = "Set owner of the mounted disk";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          # ExecStart = "${pkgs.coreutils}/bin/echo Hello, world!";
          # ExecStart = ''
          #    chown -R ${userName} ${disk}
          # '';
          ExecStart = pkgs.writeShellScript "chown-mount-disk" ''
              chown -R ${userName}:nasusers /mnt/${disk}
          '';
        };
      };
    }) indexedUUIDs);

  # Override the auto-generated mount unit:
  # systemd.services."mnt-disk001.mount".serviceConfig = {
  #   # This runs after the mount is in place:
  #   ExecStartPost = lib.concatStringsSep ";" [
  #     "echo 'Fixing ownership on /mnt/disk001…'"
  #     "chown -R alice:users /mnt/disk001"
  #   ];
  # };
}

