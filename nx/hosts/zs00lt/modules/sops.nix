{ inputs, config, lib, ... }:
let hostCfg = config.hostCfg;
in {

  sops = {
    ##########
    # wifi are dynaimcally generated from sops
    ###########
    # secrets = {
    #   "wifi/house" = { };
    #   "wifi/house5" = { };
    # };
  };
}
