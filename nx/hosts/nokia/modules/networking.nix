{ config, pkgs, NixSecrets, ... }:
let sopsFolder = NixSecrets + "/sops";
in {
  sops.secrets = {
    "nokia_password" = { sopsFile = "${sopsFolder}/nokia_cert.yaml"; };
    "nokia_private_key" = {
      mode = "0600";
      path = "/etc/ssl/nokia/client.key";
      sopsFile = "${sopsFolder}/nokia_cert.yaml";
    };
  };

  sops.templates."network-secrets.env".content = ''
    NOKIA_PK_PASSWORD=${config.sops.placeholder."nokia_password"}
  '';

  environment.etc = {
    "ssl/nokia/NOKIA_Root_CA.crt".source =
      "${NixSecrets}/certs/NOKIA_Root_CA.crt";
    "ssl/nokia/client.crt".source =
      "${NixSecrets}/certs/alfoldi.ipa.nsn-net.net.crt";
  };

  networking.networkmanager = {
    enable = true;
    plugins = [ pkgs.networkmanager-openconnect ];
    ensureProfiles = {
      environmentFiles = [ config.sops.templates."network-secrets.env".path ];
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
          wifi-security = { key-mgmt = "wpa-eap"; };
          "802-1x" = {
            eap = "tls";
            identity = "host/alfoldi.ipa.nsn-net.net";
            ca-cert = "/etc/ssl/nokia/NOKIA_Root_CA.crt";
            client-cert = "/etc/ssl/nokia/client.crt";
            private-key = "/etc/ssl/nokia/client.key";
            private-key-password = "$NOKIA_PK_PASSWORD";
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
            userkey = "/etc/ssl/nokia/client.key";

            # Plugin specific settings (underscores + strings)
            disable_udp = "no";
            pem_passphrase_fsid = "no";
            prevent_invalid_cert = "no";

            # Flags as strings
            "cookie-flags" = "2";
            "gateway-flags" = "2";
          };

          ipv4 = {
            method = "auto";
            never-default = true;
            dns-search = "cci.nokia.net;int.net.nokia.com;nsn-rdnet.net";
          };

          ipv6 = { method = "disabled"; };
        };
      };
    };
  };

}
