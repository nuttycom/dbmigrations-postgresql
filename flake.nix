{
  description = "PostgreSQL (via HDBC) runner for dbmigrations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    dbmigrations = {
      url = "github:haskell-github-trust/dbmigrations/e2840f47f819252f1cc9c6010b5c7bff5d4df763";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, dbmigrations }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkg-name = "dbmigrations-postgresql";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ dbmigrations.overlays.default ];
        };

        hspkgs = pkgs.haskellPackages.extend (hfinal: hprev: {
          ${pkg-name} = pkgs.haskell.lib.dontCheck (hfinal.callCabal2nix pkg-name ./. {});
        });
      in {
        packages = {
          ${pkg-name} = hspkgs.${pkg-name};
          default = self.packages.${system}.${pkg-name};
        };

        overlays.default = final: prev: {
          haskellPackages = prev.haskellPackages.extend (hfinal: hprev: {
            ${pkg-name} = pkgs.haskell.lib.dontCheck (hfinal.callCabal2nix pkg-name ./. {});
          });
        };

        devShells.default = hspkgs.shellFor {
          packages = p: [p.${pkg-name}];
          withHoogle = true;
          buildInputs = with hspkgs; [
            cabal-install
          ];
        };
      }
    );
}
