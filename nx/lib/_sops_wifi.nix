{ wifiNames ? [ ] }:
builtins.listToAttrs (map (name:
  let _name = builtins.trace ("_sops_wifi: name = " + toString name) name;
  in {
    name = "wifi/${_name}";
    value = { };
  }) (wifiNames))
