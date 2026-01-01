{
  description = "NR Lab - 5G NR Documentation & SDR Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # LibreSDR firmware directory (relative to flake root)
        libreSDRImagesDir = "${self}/libresdr";
        
        # Common packages
        commonPackages = with pkgs; [
          git
        ];
        
        # Documentation packages
        docsPackages = with pkgs; [
          nodejs_20
        ];
        
        # SDR packages
        sdrPackages = with pkgs; [
          # UHD driver and tools
          uhd
          
          # Spectrum analysis tools
          gqrx
          sdrpp
          
          # GNU Radio
          # gnuradio
          
          # Utilities
          python3
          python3Packages.numpy
        ];
      in
      {
        devShells = {
          # Default: docs only (lightweight)
          default = pkgs.mkShell {
            buildInputs = commonPackages ++ docsPackages;
            shellHook = ''
              echo "📖 NR Lab - Documentation Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "Node.js: $(node --version)"
              echo ""
              echo "Commands:"
              echo "  npm install        - Install dependencies"
              echo "  npm run docs:dev   - Start dev server"
              echo ""
              echo "💡 For SDR tools, use: nix develop .#sdr"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
          
          # SDR environment
          sdr = pkgs.mkShell {
            buildInputs = commonPackages ++ sdrPackages;
            
            # Use LibreSDR custom FPGA firmware
            UHD_IMAGES_DIR = libreSDRImagesDir;
            
            shellHook = ''
              echo "📡 NR Lab - SDR Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "UHD: $(uhd_config_info --version 2>/dev/null || echo 'installed')"
              echo "FPGA: $UHD_IMAGES_DIR (LibreSDR)"
              echo ""
              echo "Available tools:"
              echo "  uhd_usrp_probe     - Detect USRP devices"
              echo "  uhd_fft            - Spectrum analyzer"
              echo "  gqrx               - SDR receiver GUI"
              echo "  sdrpp              - Modern SDR receiver"
              echo "  gnuradio-companion - GNU Radio flowgraphs"
              echo ""
              echo "💡 For docs, use: nix develop .#default"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
          
          # Full environment (docs + SDR)
          full = pkgs.mkShell {
            buildInputs = commonPackages ++ docsPackages ++ sdrPackages;
            
            # Use LibreSDR custom FPGA firmware
            UHD_IMAGES_DIR = libreSDRImagesDir;
            
            shellHook = ''
              echo "🚀 NR Lab - Full Development Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "Node.js: $(node --version)"
              echo "UHD: $(uhd_config_info --version 2>/dev/null || echo 'installed')"
              echo "FPGA: $UHD_IMAGES_DIR (LibreSDR)"
              echo ""
              echo "Documentation:"
              echo "  npm run docs:dev   - Start dev server"
              echo ""
              echo "SDR Tools:"
              echo "  uhd_fft / gqrx / sdrpp / gnuradio-companion"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
        };
      }
    );
}
