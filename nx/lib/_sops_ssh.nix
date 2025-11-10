{ lib, sshDir }:
let
  allFiles = lib.filesystem.listFilesRecursive sshDir;
  yamlPaths = lib.filter (file:
    lib.strings.hasSuffix ".yaml" file || lib.strings.hasSuffix ".yml" file)
    allFiles;

  # __sshSecrets = lib.listToAttrs (builtins.map (sopsFilePath:
  #   let
  #     _name = builtins.unsafeDiscardStringContext (builtins.replaceStrings [ "${personalDir}/ssh/" ".yaml" ".yml" ] [ "" "" "" ] sopsFilePath) ;
  #   in {
  #     name = _name;
  #     value = {
  #       sopsFile = sopsFilePath;
  #       key = "data";
  #     };
  #   }) yamlPaths);

  mkSecret = sopsFilePath:
    let
      name = "ssh/" + builtins.unsafeDiscardStringContext
        (builtins.replaceStrings [ "${toString sshDir}/" ".yaml" ".yml" ] [
          ""
          ""
          ""
        ] sopsFilePath);
    in {
      inherit name;
      value = {
        sopsFile = sopsFilePath;
        key = "data";
      };
    };
in lib.listToAttrs (map mkSecret yamlPaths)
