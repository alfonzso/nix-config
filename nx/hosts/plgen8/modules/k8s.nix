{ config, pkgs, NixSecrets, ... }:
let
  hostCfg = config.hostCfg;
  sopsFolder = NixSecrets + "/sops";
in {
  services.k3s = {
    enable = true;
    extraFlags = toString [
      "--disable traefik" # Optional: disable if you don't need it
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80 # enable for haproxy
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];

  users.users.${hostCfg.username} = { extraGroups = [ "k3s" ]; };
  users.groups.k3s = { };

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

  environment.systemPackages = with pkgs; [ fluxcd ];

  sops = {
    secrets = {
      "fluxcd_gh_token" = { sopsFile = "${sopsFolder}/gitops.yaml"; };
    };
    templates."FLUXCD_ENV".content = ''
      GITHUB_TOKEN=${config.sops.placeholder.fluxcd_gh_token}
    '';
  };

  # Auto-install Flux after k3s starts
  systemd.services.flux-install = {
    description = "Install FluxCD";
    after = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.k3s pkgs.fluxcd ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
      EnvironmentFile = config.sops.templates.FLUXCD_ENV.path;
    };
    script = ''
      # Wait for k3s to be ready
      until kubectl get nodes 2>/dev/null; do
        echo "Waiting for k3s..."
        sleep 5
      done

      # Install flux if not already installed
      if ! kubectl get ns flux-system 2>/dev/null; then
        flux install
        flux bootstrap github \
          --token-auth \
          --owner=alfonzso \
          --repository=flux-at-home \
          --branch=main \
          --path=clusters/production \
          --personal
      fi
    '';
  };
}
