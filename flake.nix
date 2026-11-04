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
  inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nordfra = {
    url = "https://github.com/FjellOverflow/nordfra/releases/download/v0.3.4/nordfra.tar.gz";
    flake = false;
  };

  outputs =
    {
      nixpkgs,
      nix-flatpak,
      nix-vscode-extensions,
      home-manager,
      nix-index-database,
      spicetify-nix,
      nordfra,
      ...
    }:
    let
      variables = import ./variables.nix;
      inherit (variables) user;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lint = pkgs.writeShellApplication {
        name = "lint";
        runtimeInputs = with pkgs; [
          statix
          deadnix
          nixfmt
          findutils
          git
        ];
        text = ''
          statix check .
          git ls-files -z '*.nix' | xargs -0 deadnix --fail
          git ls-files -z '*.nix' | xargs -0 nixfmt --check
        '';
      };
      format = pkgs.writeShellApplication {
        name = "format";
        runtimeInputs = with pkgs; [
          nixfmt
          findutils
          git
        ];
        text = ''
          git ls-files -z '*.nix' | xargs -0 nixfmt
        '';
      };
      machines = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./machines)
      );
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
      packages.${system} = { inherit lint format; };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.statix
          pkgs.deadnix
          pkgs.nixfmt
          lint
          format
        ];
      };

      nixosConfigurations = nixpkgs.lib.genAttrs machines (
        host:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              variables
              user
              spicetify-nix
              nordfra
              ;
          };
          modules = commonModules ++ [ ./machines/${host}/default.nix ];
        }
      );
    };
}
