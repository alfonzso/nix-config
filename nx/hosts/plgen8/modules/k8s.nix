{ config, pkgs, ... }:
let hostCfg = config.hostCfg;
in {
  services.k3s.enable = true;
  # services.k3s.enable = false;
  users.users.${hostCfg.username} = { extraGroups = [ "k3s" ]; };
  users.groups.k3s = {};

  home-manager = {
    users.${hostCfg.username} = {
      home.sessionVariables = { KUBECONFIG = "/etc/rancher/k3s/k3s.yaml"; };
    };
  };

  # Make k3s.yaml readable by k3s group
  systemd.services.k3s.serviceConfig = {
    ExecStartPost = [
      "${pkgs.coreutils}/bin/chmod 640 /etc/rancher/k3s/k3s.yaml"
      "${pkgs.coreutils}/bin/chgrp k3s /etc/rancher/k3s/k3s.yaml"
    ];
  };
}
