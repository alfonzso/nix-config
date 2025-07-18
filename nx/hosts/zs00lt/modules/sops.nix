{ inputs, config, lib, ... }:
let hostCfg = config.hostCfg;
in {

  sops = {
    secrets = {
      "wifi/house" = { };
      "wifi/house5" = { };
    };
  };
}
