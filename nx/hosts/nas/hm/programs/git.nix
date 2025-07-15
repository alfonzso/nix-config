{
config,
pkgs,
hostCfg,
...
}:
# let
#   hostCfg = config.hostCfg ;
# in
{
    programs.git = {
      enable = true;
      userName  = "alfonzso";
      userEmail = "alfonzso@gmail.com";
    };

}
