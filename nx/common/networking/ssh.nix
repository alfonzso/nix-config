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
      X11Forwarding = true;
    };
  };

  services.sshguard = {
    enable = true;
    services = [ "sshd" "sshd-session" ];
  };

}
