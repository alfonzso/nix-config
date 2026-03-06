{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs.url = "github:nixos/nixpkgs/master";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      # url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+ssh://git@github.com/alfonzso/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };

    himmelblau = {
      url = "github:himmelblau-idm/himmelblau";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # rust-overlay = {
    #   url = "github:oxalica/rust-overlay";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # rust-overlay
  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      home-manager,
      himmelblau,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      system = "x86_64-linux";
      # pkgs = import nixpkgs {
      #   inherit system ;
      #   # config.allowUnfree = true;
      #   # config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
      # };
      # system = "x86_64-linux";
      # pkgs = import nixpkgs {
      #   inherit system;
      #   overlays = [ rust-overlay.overlays.default ];
      # };

      #
      # ========= Architectures =========
      #
      # forAllSystems = nixpkgs.lib.genAttrs [
      #   "x86_64-linux"
      #   #"aarch64-darwin"
      # ];

      # pkgsUnstable = import unstable {
      #   inherit system;
      #   config.allowUnfree = true;
      #
      #   overlays = [
      #     (self: super: {
      #       # override allowUnfree for the package set
      #       config = super.config // { allowUnfree = true; };
      #     })
      #   ];
      # };

      #
      # ========= flakeConfigName Config Functions =========
      #
      # Handle a given flakeConfigName config based on whether its underlying system is nixos or darwin
      mkHost = flakeConfigName: {
        ${flakeConfigName} =
          let
            systemFunc = lib.nixosSystem;
            # NixSecrets = builtins.toString inputs.nix-secrets ;
          in
          systemFunc {
            specialArgs = {
              ProjectRoot = ./.;
              DiskoTesting = false;
              NixSecrets = builtins.toString inputs.nix-secrets;
              inherit inputs outputs;

              # ========== Extend lib with lib.custom ==========
              # NOTE: This approach allows lib.custom to propagate into hm
              # see: https://github.com/nix-community/home-manager/pull/3454
              # lib = nixpkgs.lib.extend (self: super: { custom = import ./lib { inherit (nixpkgs) lib; }; });

            };
            modules = [
              # ./flake-caches/cachix.nix
              himmelblau.nixosModules.himmelblau

              ./nx/common/host_cfg.nix
              ./nx/hosts/${flakeConfigName}

              home-manager.nixosModules.home-manager
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              {
                hostCfg.machineHostName = flakeConfigName + "Nix";
                hostCfg.currentConfigName = flakeConfigName;
                # hostCfg.nasUser = "nasadmin";
                # hostCfg.nasGroup = "nasuser";
                hostCfg.root = ./.;
              }
              # { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
              (
                { config, lib, ... }:
                {
                  config._module.args.personal = import "${inputs.nix-secrets}/personal" { };
                }
              )
            ];
          };
      };
      # Invoke mkHost for each flakeConfigName config that is declared for either nixos or darwin
      mkHostConfigs =
        hosts:
        lib.foldl (acc: set: acc // set) { } (lib.map (flakeConfigName: mkHost flakeConfigName) hosts);
      # Return the hosts declared in the given directory
      readHosts = lib.attrNames (builtins.readDir ./nx/hosts);

    in
    {
      nixosConfigurations = mkHostConfigs (readHosts);
    };
}
