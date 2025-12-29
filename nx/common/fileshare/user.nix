{ config, ... }: {
  users.groups."${config.hostCfg.nasGroup}" = { };
  users.users.${config.hostCfg.nasUser} = {
    isNormalUser = true;
    group = "${config.hostCfg.nasGroup}";
    extraGroups = [ "${config.hostCfg.nasGroup}" "users" ];
  };
}
