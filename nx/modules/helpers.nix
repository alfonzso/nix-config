{
  config,
  ...
}:
{
  isEmpty = value:
  	value == null ||
	(builtins.isList value && value == []) ||
	(builtins.isString value && value == "") ||
	(builtins.isAttrs value && builtins.attrNames value == []);

  genNetworks =  wifiList :
    builtins.listToAttrs (map (name: {
      inherit name;
      value = { psk = config.sops.secrets."wifi/${name}".path; };
    }) wifiList);
    
  genSecrets =  wifiList: {
    wifi = builtins.listToAttrs (map (name: {
      inherit name;
      value = {} ;
    }) wifiList);
  };

}
