{ lib, mkHost, ... }:
let
  readTestHosts = lib.attrNames (builtins.readDir ./hosts);
  sourceHostFromTestHost = outputName: lib.removePrefix "test-" outputName;

  mkTestHost =
    outputName:
    let
      sourceHost = sourceHostFromTestHost outputName;
    in
    mkHost {
      flakeConfigName = sourceHost;
      inherit outputName;
      hostPath = ./hosts/${outputName};
      currentConfigName = sourceHost;
      diskoTesting = true;
    };
in
lib.foldl (acc: outputName: acc // mkTestHost outputName) { } readTestHosts
