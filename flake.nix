{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url =
        "git+ssh://git@github.com/alfonzso/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };
  };

  outputs = { self, nixpkgs, disko, sops-nix, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;

      #
      # ========= Architectures =========
      #
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        #"aarch64-darwin"
      ];

      #
      # ========= Host Config Functions =========
      #
      # Handle a given host config based on whether its underlying system is nixos or darwin
      mkHost = host: {
        ${host} = let
          systemFunc = lib.nixosSystem;
          # NixSecrets = builtins.toString inputs.nix-secrets ;
        in systemFunc {
          specialArgs = {
            HostName = host;
            ProjectRoot = ./.;
            NixSecrets = builtins.toString inputs.nix-secrets;
            # KeK         = config.hostCfg
            # HostCfg =  import ./nx/modules/_host.cfg.nix {inherit  lib NixSecrets; } ;
            # HostCfg =  import ./nx/modules/_host.cfg.nix {inherit lib ... ; } ;
            inherit inputs outputs;

            # ========== Extend lib with lib.custom ==========
            # NOTE: This approach allows lib.custom to propagate into hm
            # see: https://github.com/nix-community/home-manager/pull/3454
            # lib = nixpkgs.lib.extend (self: super: { custom = import ./lib { inherit (nixpkgs) lib; }; });

          };
          modules = [
            ./nx/modules/_host.cfg.nix
            ./nx/hosts/${host}
            home-manager.nixosModules.home-manager
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            {
              disko.rootMountPoint = "/mnt";
              disko.devices = import ./nx/modules/disko/${host}.nix;
            }
            ({ config, lib, ... }: {
              config._module.args.personal =
                import "${inputs.nix-secrets}/nix/personal.nix" { };
            })
          ];
        };
      };
      # Invoke mkHost for each host config that is declared for either nixos or darwin
      mkHostConfigs = hosts:
        lib.foldl (acc: set: acc // set) { }
        (lib.map (host: mkHost host) hosts);
      # Return the hosts declared in the given directory
      readHosts = lib.attrNames (builtins.readDir ./nx/hosts);

    in {
      nixosConfigurations = mkHostConfigs (readHosts);
      # nixosConfigurations.zs00ltNix = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     ./configuration.nix # { inherit inputs; }
      #   ];
      # };
    };
}
