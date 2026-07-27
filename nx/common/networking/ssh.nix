{ ... }: {

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      PerSourcePenalties = "authfail:3600s max:86400s";
      PerSourcePenaltyExemptList = "192.168.0.0/16";
      X11Forwarding = true;
    };
  };

  services.sshguard = {
    enable = true;
    services = [ "sshd" "sshd-session" ];
    whitelist = [ "192.168.0.0/16" ];
  };

}
