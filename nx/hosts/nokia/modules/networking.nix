{
  config,
  pkgs,
  NixSecrets,
  personal,
  ...
}:
let
  sopsFolder = NixSecrets + "/sops";
in
{

  # Decrypt to /run (tmpfs, never hits disk, gone on reboot)
  systemd.services.decrypt-vpn-key = {
    description = "Decrypt VPN private key";
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /run/nokia-vpn
      ${pkgs.openssl}/bin/openssl rsa \
        -in /etc/ssl/nokia/client.key \
        -out /run/nokia-vpn/client.key \
        -passin file:${config.sops.secrets."nokia_pem_password".path}
      chmod 640 /run/nokia-vpn/client.key
    '';
  };

  # added group to our user so it can open/edit network configs without password
  users.users."${config.hostCfg.username}".extraGroups = [ "networkmanager" ];

  sops.secrets = {
    "nokia_pem_password" = {
      sopsFile = "${sopsFolder}/nokia_cert.yaml";
    };
    "nokia_private_key" = {
      mode = "0600";
      path = "/etc/ssl/nokia/client.key";
      sopsFile = "${sopsFolder}/nokia_cert.yaml";
    };
    "ms_password" = {
      sopsFile = "${sopsFolder}/nokia.yaml";
    };
  };

  sops.templates."nokia-user-password".content = ''
    NOKIA_USER_PASSWORD=${config.sops.placeholder."ms_password"}
  '';

  environment.etc = {
    "ssl/nokia/NOKIA_Root_CA.crt".source = "${NixSecrets}/certs/NOKIA_Root_CA.crt";
    "ssl/nokia/client.crt".source = "${NixSecrets}/certs/alfoldi.ipa.nsn-net.net.crt";
  };

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
    ensureProfiles = {
      environmentFiles = [ config.sops.templates."nokia-user-password".path ];
      profiles = {
        nokia-wifi = {
          connection = {
            id = "NOSI";
            type = "wifi";
          };
          wifi = {
            ssid = "NOKIA";
            mode = "infrastructure";
          };
          wifi-security = {
            key-mgmt = "wpa-eap";
          };
          "802-1x" = {
            eap = "tls";
            identity = "host/alfoldi.ipa.nsn-net.net";
            ca-cert = "/etc/ssl/nokia/NOKIA_Root_CA.crt";
            client-cert = "/etc/ssl/nokia/client.crt";
            private-key = "/run/nokia-vpn/client.key";
            # "/etc/ssl/nokia/client.key";
            # private-key-password = "$NOKIA_PEM_PASSWORD";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };

        nokia-vpn = {
          connection = {
            id = "NokiaVPN";
            type = "vpn";
            autoconnect = false;
          };

          vpn = {
            "service-type" = "org.freedesktop.NetworkManager.openconnect";

            protocol = "anyconnect";
            gateway = "nra-emea-fr-gre-vip.alcatel-lucent.com";
            authtype = "cert";
            cacert = "/etc/ssl/nokia/NOKIA_Root_CA.crt";
            usercert = "/etc/ssl/nokia/client.crt";
            # userkey = "/etc/ssl/nokia/client.key";
            userkey = "/run/nokia-vpn/client.key";

            # Plugin specific settings (underscores + strings)
            disable_udp = "no";
            pem_passphrase_fsid = "no";
            prevent_invalid_cert = "no";

            # Flags as strings
            "cookie-flags" = "0";
            "gateway-flags" = "0";
          };

          # vpn-secrets = {
          #   "userkey-password" = "$NOKIA_PEM_PASSWORD";
          # };

          vpn-secrets = {
            "form:main:username" = "${personal.email.work}";
            "password" = "$NOKIA_USER_PASSWORD";
            "save_passwords" = "yes";
            "autoconnect" = "yes";
            "lasthost" = "Global - Germany - Frankfurt - 1";
          };

          ipv4 = {
            method = "auto";
            never-default = true;
            dns-search = "cci.nokia.net;int.net.nokia.com;nsn-rdnet.net";
          };

          ipv6 = {
            method = "disabled";
          };
        };
      };
    };
  };

}
