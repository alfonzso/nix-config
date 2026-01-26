{ ... }: {

  # NOTE: intune service not working yet with nokia
  # date: 2026.01.26
  # 1) you cannot register your machine via intune-portal
  # 2) if you reach that point to check is your machine will complaint with nokia/ms rules, it wont ...
  # with nixos 25.11 and use intune with master branch (26.01?)
  # intune will try to check your machine is compliant but result will be: your machine cannot register
  # check it later or something like that, and journalctl doesnt show any error
  # I will keep this config, maybe in the future it will work...

  # # intune service will install all of the packages what u need for intune
  # # like broker and systemd services
  # services.intune.enable = true;
  # xdg.portal.enable = true;
  # security.polkit.enable = true;
  #
  # # not sure its needed here or not (its from ubuntu)
  # security.polkit.extraConfig = ''
  #   polkit.addAdminRule(function(action, subject) {
  #       return ["unix-group:wheel", "unix-group:sudo"];
  #   });
  #
  #   polkit.addRule(function(action, subject) {
  #       if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
  #           subject.local && subject.active &&
  #           (subject.isInGroup("wheel") || subject.isInGroup("networkmanager"))) {
  #           return polkit.Result.YES;
  #       }
  #   });
  # '';
  #
  # environment.systemPackages = with pkgs; [
  #   microsoft-edge
  #   libGLU
  #   libGL
  #   glib
  # ];
}
