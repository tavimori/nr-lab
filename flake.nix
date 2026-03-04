{
  description = "NR Lab - 5G NR Documentation & SDR Development Environment";

  # Binary cache configuration for pre-built srsran-project
  nixConfig = {
    extra-substituters = [ "https://nr-lab.cachix.org" ];
    extra-trusted-public-keys = [ "nr-lab.cachix.org-1:Yxp09CtuwlBg24SbYXNjVLfdoMROdZUwTXs4xaAGs20=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Open5GS built from source (local fork with Nix flake)
    open5gs = {
      url = "git+file:///home/licheng/Projects/open5gs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, open5gs }:
    # ═══════════════════════════════════════════════════════════════════════════
    # NixOS Modules (system-independent)
    # ═══════════════════════════════════════════════════════════════════════════
    {
      nixosModules = {
        # Open5GS 5G/LTE Core Network module
        open5gs = import ./modules/open5gs;
        
        # Alias for convenience
        default = self.nixosModules.open5gs;
      };
    } //
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Per-system outputs (devShells, packages)
    # ═══════════════════════════════════════════════════════════════════════════
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Overlay for custom packages
        overlay = final: prev: {
          srsran-project = final.callPackage ./packages/srsran-project.nix { };
          open5gs = open5gs.packages.${system}.open5gs;
        };
        
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        
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
        
        # 5G packages (gNB + 5GC)
        fiveGPackages = [
          # 5G Core Network
          pkgs.open5gs
          
          # 5G gNB (custom build from srsRAN Project)
          pkgs.srsran-project
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
          
          # 5G environment (gNB + 5GC)
          "5g" = pkgs.mkShell {
            buildInputs = commonPackages ++ sdrPackages ++ fiveGPackages;
            
            # Use LibreSDR custom FPGA firmware
            UHD_IMAGES_DIR = libreSDRImagesDir;
            
            shellHook = ''
              echo "📶 NR Lab - 5G Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "UHD: $(uhd_config_info --version 2>/dev/null || echo 'installed')"
              echo "FPGA: $UHD_IMAGES_DIR (LibreSDR)"
              echo ""
              echo "5G Core (Open5GS):"
              echo "  open5gs-*          - 5GC network functions"
              echo ""
              echo "5G gNB (srsRAN Project):"
              echo "  gnb                - 5G gNB application"
              echo ""
              echo "💡 For docs, use: nix develop .#default"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
          
          # Full environment (docs + SDR + 5G)
          full = pkgs.mkShell {
            buildInputs = commonPackages ++ docsPackages ++ sdrPackages ++ fiveGPackages;
            
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
              echo ""
              echo "5G Stack:"
              echo "  open5gs-* (5GC) / gnb (gNB)"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
        };
      }
    );
}
