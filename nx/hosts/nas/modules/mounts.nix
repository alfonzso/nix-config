{ config, pkgs, lib, ... }:

let
  diskUUIDs = [
    "d8fd4b40-38c2-4ef3-b8e3-d383f9a1470e"
    "883e96f9-df17-4a9f-b233-7c75330c6e4d"
    "36691558-2c47-4492-b479-1a43d295e4e3"
  ];

  indexedUUIDs =
    lib.zipLists (map toString (lib.range 1 (builtins.length diskUUIDs)))
    diskUUIDs;
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
      };
    }) indexedUUIDs);
}

