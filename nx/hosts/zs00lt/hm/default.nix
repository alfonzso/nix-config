{
config, lib, pkgs, ...
}:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  ProjectRoot = config.hostCfg.root;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs" ;
in {

  # imports = [
  #   ./${_hm_common}/programs.nix
  #   ./packages.nix
  # ];

  home-manager = {
    extraSpecialArgs = {
      # inherit pkgs inputs;
      hostCfg = config.hostCfg;
    };

    useUserPackages = true;
    useGlobalPkgs = true;

    users.${hostCfg.username} = {

      imports = [
        "${_hm_programs}"
        ./packages.nix
      ];

      home = {

        activation.createCustomDir = lib.mkAfter ''
          mkdir -p ${vimTMP} || true
          chmod u+rw ${vimTMP}
        '';
        activation.cloneGitRepo = lib.mkAfter ''
          export PATH=${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH
          if [ ! -d "$HOME/.config/nvim/.git" ]; then
            git clone git@github.com:alfonzso/nvim.git $HOME/.config/nvim
          fi
        '';

        username = hostCfg.username;
        # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = "24.11";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

}
