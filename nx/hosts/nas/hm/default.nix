{ config, lib, pkgs, ... }:
let
  hostCfg = config.hostCfg;
  homeDir = "/home/${hostCfg.username}";
  vimTMP = "${homeDir}/.vim-tmp";
  # sambaPassPath = config.sops.secrets.samba_user_pwd.path;
  ProjectRoot = config.hostCfg.root;
  _hm_programs = ProjectRoot + "/nx/common/hm_programs" ;


#   myRepo = pkgs.fetchFromGitHub {
#     owner = "alfonzso";
#     repo  = "nvim";
#     rev   = "17ce152aa283b497512884468389f822b348276a";    # e.g. "v1.2.3" or commit hash
#     sha256 = "sha256-0vg8gs10c3vj79p4c1p4g3xs1y62lf0grvka19h9xywk3whlixyc"
# # "hash": "sha256-zPdIIR+T+55gCmru/ICjwvig+3jkBkZuOnIPBoJ+6G0=",
#   };

  # myNvim = builtins.fetchGit {
  #   url = "git@github.com:alfonzso/nvim.git";
  #   ref = "main";
  #   rev = "17ce152aa283b497512884468389f822b348276a";
  # }

  myNvimSrc = builtins.fetchGit {
    url = "ssh://git@github.com/alfonzso/nvim.git";
    ref = "refs/heads/main";
    rev = "17ce152aa283b497512884468389f822b348276a";
    allRefs = true;
  };

in {
  home-manager = {
    extraSpecialArgs = { hostCfg = config.hostCfg; };

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

        file.".config/nvim".source = myNvim;

        # activation.cloneGitRepo = lib.mkAfter ''
        #   export PATH=${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH
        #   if [ ! -d "$HOME/.config/nvim/.git" ]; then
        #     git clone git@github.com:alfonzso/nvim.git $HOME/.config/nvim
        #     nix-prefetch-git https://github.com/alfonzso/nvim.git --rev master 
        #   fi
        # '';

        # 0vg8gs10c3vj79p4c1p4g3xs1y62lf0grvka19h9xywk3whlixyc

        username = hostCfg.username;
        # This needs to actually be set to your username
        homeDirectory = homeDir;
        # You do not need to change this if you're reading this in the future.
        # Don't ever change this after the first build.  Don't ask questions.
        stateVersion = "25.05";

        sessionVariables = { POETRY_VIRTUALENVS_IN_PROJECT = "true"; };
      };
    };
  };

}
