{ lib, mkHost, ... }:
let
  testHosts = {
    test-c0r3 = {
      sourceHost = "c0r3";
      hostPath = ./hosts/c0r3;
    };
  };

  mkTestHost =
    outputName:
    {
      sourceHost,
      hostPath,
    }:
    mkHost {
      flakeConfigName = sourceHost;
      inherit outputName hostPath;
      currentConfigName = sourceHost;
      diskoTesting = true;
    };
in
lib.foldl (acc: outputName: acc // mkTestHost outputName testHosts.${outputName}) { } (
  builtins.attrNames testHosts
)
