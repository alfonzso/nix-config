{
 config,
 pkgs,
 lib,
 ...
}:

{

  options = {
    hostCfg = { 
      _lib = lib.mkOption {
        type = lib.types.attrs;
        default = import ./helpers.nix { inherit config; } ;
        description = "Helpers of nix-config";
      };
      root = lib.mkOption {
        type = lib.types.path;
        default = ./. ; 
        description = "Global root path for shared resources";
      };
      username = lib.mkOption {
        type = lib.types.str;
        default = "admin" ; 
        description = "User of the machine";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "zs00lt" ; 
        description = "Hostname of the machine";
      };
    };
  };

}
