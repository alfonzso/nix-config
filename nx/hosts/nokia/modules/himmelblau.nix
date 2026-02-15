{ ... }:

let userMapPath = "/etc/himmelblau/user_map";
in {
  # imports = [ pkgs.himmelblau.nixosModules.himmelblau ];

  # Enable the service
  services.himmelblau = {
    enable = true;

    settings = {
      domain =
        [ "nokia.com" ]
      ;
      # apply_policy = true;
      apply_policy = false;

      # Map Entra UPN → local Linux user
      user_map_file = userMapPath;

      # Optional hardening
      # pam_allow_groups = [ "ENTRA-GROUP-GUID-HERE" ];
      local_groups = [ "wheel" "docker" ];
    };
  };

  # Declarative user map
  environment.etc."himmelblau/user_map".text = ''
    zsolt.alfoldi@nokia.com alfoldi
  '';
}
