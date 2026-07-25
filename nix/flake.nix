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

  outputs =
    {
      nixpkgs,
      nix-flatpak,
      nix-vscode-extensions,
      home-manager,
      nix-index-database,
      nixpkgs-2511,
      ...
    }:
    let
      user = "fjelloverflow";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lint = pkgs.writeShellApplication {
        name = "lint";
        runtimeInputs = with pkgs; [
          statix
          deadnix
          nixfmt
          findutils
        ];
        text = ''
          statix check .
          deadnix --fail .
          find . -name '*.nix' -exec nixfmt --check {} +
        '';
      };
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
      packages.${system}.lint = lint;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.statix
          pkgs.deadnix
          pkgs.nixfmt
          lint
        ];
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
