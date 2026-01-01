{
  description = "NR Lab - 5G NR Documentation Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js LTS
            nodejs_20
            # Package manager (npm is included with nodejs)
          ];

          shellHook = ''
            echo "🚀 NR Lab Development Environment"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "Node.js: $(node --version)"
            echo "npm: $(npm --version)"
            echo ""
            echo "Commands:"
            echo "  npm install        - Install dependencies"
            echo "  npm run docs:dev   - Start dev server"
            echo "  npm run docs:build - Build for production"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          '';
        };
      }
    );
}

