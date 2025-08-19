{ ... }: {

  isEmpty = value:
    value == null || (builtins.isList value && value == [ ])
    || (builtins.isString value && value == "")
    || (builtins.isAttrs value && builtins.attrNames value == [ ]);

}
