{
  description = "NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  inputs.nix-vscode-extensions = {
    url = "github:nix-community/nix-vscode-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.git-hooks = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-flatpak,
      nix-vscode-extensions,
      home-manager,
      nix-index-database,
      nixpkgs-2511,
      git-hooks,
    }:
    let
      user = "fjelloverflow";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      commonModules = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        { nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ]; }
        nix-index-database.nixosModules.nix-index
        ./base/common.nix
      ];
    in
    {
      checks.${system}.pre-commit = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          statix.enable = true;
          deadnix.enable = true;
          nixfmt.enable = true;
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit) shellHook;
        buildInputs = self.checks.${system}.pre-commit.enabledPackages;
      };

      nixosConfigurations = {
        vm = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit user; };
          modules = commonModules ++ [ ./machines/vm/default.nix ];
        };
        thinkpad = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit user; };
          modules = commonModules ++ [ ./machines/thinkpad/default.nix ];
        };
        brick = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit user nixpkgs-2511; };
          modules = commonModules ++ [ ./machines/brick/default.nix ];
        };
        gigabyte = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit user; };
          modules = commonModules ++ [ ./machines/gigabyte/default.nix ];
        };
      };
    };
}
