# NR Lab - Open5GS NixOS Module
# 
# This module provides declarative configuration for Open5GS 5G/LTE core network.
# It manages all Open5GS network functions as systemd services.
#
# Usage in your NixOS configuration:
#   imports = [ inputs.nr-lab.nixosModules.open5gs ];
#   services.open5gs = {
#     enable = true;
#     # ... configuration options
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.open5gs;
  
  # Helper to generate YAML configuration files
  yamlFormat = pkgs.formats.yaml { };
  
  # Common network function service generator
  mkNfService = name: configFile: {
    description = "Open5GS ${lib.toUpper name}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ] 
      ++ lib.optional cfg.mongodb.enable "mongodb.service"
      ++ lib.optional (name != "nrf") "open5gs-nrf.service";
    requires = lib.optional cfg.mongodb.enable "mongodb.service";
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${cfg.package}/bin/open5gs-${name}d -c ${configFile}";
      Restart = "on-failure";
      RestartSec = "5s";
      
      # Security hardening
      DynamicUser = lib.mkDefault true;
      StateDirectory = "open5gs";
      ConfigurationDirectory = "open5gs";
      
      # Allow binding to privileged ports if needed
      AmbientCapabilities = lib.mkIf (name == "upf") [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = lib.mkIf (name == "upf") [ "CAP_NET_ADMIN" ];
    };
  };
  
  # Default addresses for internal communication
  defaultAddresses = {
    nrf = "127.0.0.10";
    scp = "127.0.0.200";
    amf = "127.0.0.5";
    smf = "127.0.0.4";
    upf = "127.0.0.7";
    ausf = "127.0.0.11";
    udm = "127.0.0.12";
    udr = "127.0.0.20";
    pcf = "127.0.0.13";
    nssf = "127.0.0.14";
    bsf = "127.0.0.15";
    # LTE specific
    mme = "127.0.0.2";
    hss = "127.0.0.8";
    sgwc = "127.0.0.3";
    sgwu = "127.0.0.6";
    pcrf = "127.0.0.9";
  };

in {
  options.services.open5gs = {
    enable = lib.mkEnableOption "Open5GS 5G/LTE Core Network";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.open5gs;
      defaultText = lib.literalExpression "pkgs.open5gs";
      description = "The Open5GS package to use.";
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Network Mode Selection
    # ═══════════════════════════════════════════════════════════════════════════
    
    mode = lib.mkOption {
      type = lib.types.enum [ "5g-sa" "lte" "both" ];
      default = "5g-sa";
      description = ''
        Network mode to deploy:
        - `5g-sa`: 5G Standalone (NRF, SCP, AMF, SMF, UPF, AUSF, UDM, UDR, PCF, NSSF, BSF)
        - `lte`: LTE/4G (MME, HSS, SGWC, SGWU, SMF, UPF, PCRF)
        - `both`: Both 5G SA and LTE (for NSA or migration scenarios)
      '';
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # PLMN Configuration
    # ═══════════════════════════════════════════════════════════════════════════
    
    plmn = {
      mcc = lib.mkOption {
        type = lib.types.str;
        default = "001";
        description = "Mobile Country Code (3 digits). Use 001 for testing.";
      };
      
      mnc = lib.mkOption {
        type = lib.types.str;
        default = "01";
        description = "Mobile Network Code (2-3 digits). Use 01 for testing.";
      };
    };
    
    tac = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Tracking Area Code.";
    };
    
    networkName = lib.mkOption {
      type = lib.types.str;
      default = "NR Lab";
      description = "Network name displayed on devices.";
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # User Plane Configuration
    # ═══════════════════════════════════════════════════════════════════════════
    
    userPlane = {
      subnet = lib.mkOption {
        type = lib.types.str;
        default = "10.45.0.0/16";
        description = "UE IP address pool subnet.";
      };
      
      gateway = lib.mkOption {
        type = lib.types.str;
        default = "10.45.0.1";
        description = "Gateway IP for UE traffic (assigned to ogstun interface).";
      };
      
      dnn = lib.mkOption {
        type = lib.types.str;
        default = "internet";
        description = "Data Network Name (APN for LTE).";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # MongoDB Configuration
    # ═══════════════════════════════════════════════════════════════════════════
    
    mongodb = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable and configure MongoDB for Open5GS.";
      };
      
      uri = lib.mkOption {
        type = lib.types.str;
        default = "mongodb://127.0.0.1:27017/open5gs";
        description = "MongoDB connection URI.";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Network Addresses
    # ═══════════════════════════════════════════════════════════════════════════
    
    addresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = defaultAddresses;
      description = "IP addresses for each network function.";
    };
    
    ngap = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.5";
        description = "NGAP (N2) interface address for gNB connection.";
      };
      
      port = lib.mkOption {
        type = lib.types.port;
        default = 38412;
        description = "NGAP SCTP port.";
      };
    };
    
    gtpu = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.7";
        description = "GTP-U (N3) interface address for user plane.";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # TUN Device Configuration
    # ═══════════════════════════════════════════════════════════════════════════
    
    tun = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create and configure the ogstun interface.";
      };
      
      device = lib.mkOption {
        type = lib.types.str;
        default = "ogstun";
        description = "Name of the TUN device for UE traffic.";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # NAT Configuration
    # ═══════════════════════════════════════════════════════════════════════════
    
    nat = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable NAT for UE traffic.";
      };
      
      outInterface = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Outbound interface for NAT. If null, uses the default route interface.
        '';
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Custom Configuration Files (Advanced)
    # ═══════════════════════════════════════════════════════════════════════════
    
    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing custom configuration files.
        If set, these files will be used instead of generated configurations.
        Files should be named: nrf.yaml, amf.yaml, smf.yaml, etc.
      '';
    };
  };
  
  # ═══════════════════════════════════════════════════════════════════════════════
  # Implementation
  # ═══════════════════════════════════════════════════════════════════════════════
  
  config = lib.mkIf cfg.enable {
    
    # Ensure Open5GS package is available
    environment.systemPackages = [ cfg.package ];
    
    # ─────────────────────────────────────────────────────────────────────────────
    # MongoDB Service
    # ─────────────────────────────────────────────────────────────────────────────
    
    services.mongodb = lib.mkIf cfg.mongodb.enable {
      enable = true;
    };
    
    # ─────────────────────────────────────────────────────────────────────────────
    # NAT Configuration
    # ─────────────────────────────────────────────────────────────────────────────
    
    networking.nftables = lib.mkIf cfg.nat.enable {
      enable = true;
      tables.open5gs-nat = {
        family = "ip";
        content = ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            ip saddr ${cfg.userPlane.subnet} masquerade
          }
        '';
      };
    };
    
    # ─────────────────────────────────────────────────────────────────────────────
    # Configuration Files
    # ─────────────────────────────────────────────────────────────────────────────
    
    environment.etc = let
      # Import configuration generators
      configs = import ./configs.nix { inherit lib cfg defaultAddresses; };
    in lib.mkMerge [
      # Always needed: NRF (5G) or common components
      (lib.mkIf (cfg.mode == "5g-sa" || cfg.mode == "both") {
        "open5gs/nrf.yaml".source = yamlFormat.generate "nrf.yaml" configs.nrf;
        "open5gs/scp.yaml".source = yamlFormat.generate "scp.yaml" configs.scp;
        "open5gs/amf.yaml".source = yamlFormat.generate "amf.yaml" configs.amf;
        "open5gs/smf.yaml".source = yamlFormat.generate "smf.yaml" configs.smf;
        "open5gs/upf.yaml".source = yamlFormat.generate "upf.yaml" configs.upf;
        "open5gs/ausf.yaml".source = yamlFormat.generate "ausf.yaml" configs.ausf;
        "open5gs/udm.yaml".source = yamlFormat.generate "udm.yaml" configs.udm;
        "open5gs/udr.yaml".source = yamlFormat.generate "udr.yaml" configs.udr;
        "open5gs/pcf.yaml".source = yamlFormat.generate "pcf.yaml" configs.pcf;
        "open5gs/nssf.yaml".source = yamlFormat.generate "nssf.yaml" configs.nssf;
        "open5gs/bsf.yaml".source = yamlFormat.generate "bsf.yaml" configs.bsf;
      })
      
      # LTE specific components
      (lib.mkIf (cfg.mode == "lte" || cfg.mode == "both") {
        "open5gs/mme.yaml".source = yamlFormat.generate "mme.yaml" configs.mme;
        "open5gs/hss.yaml".source = yamlFormat.generate "hss.yaml" configs.hss;
        "open5gs/sgwc.yaml".source = yamlFormat.generate "sgwc.yaml" configs.sgwc;
        "open5gs/sgwu.yaml".source = yamlFormat.generate "sgwu.yaml" configs.sgwu;
        "open5gs/pcrf.yaml".source = yamlFormat.generate "pcrf.yaml" configs.pcrf;
      })
    ];
    
    # ─────────────────────────────────────────────────────────────────────────────
    # Systemd Services
    # ─────────────────────────────────────────────────────────────────────────────
    
    systemd.services = lib.mkMerge [
      # TUN Device Setup
      (lib.mkIf cfg.tun.enable {
        open5gs-ogstun = {
          description = "Open5GS TUN Device Setup";
          wantedBy = [ "multi-user.target" ];
          before = [ "open5gs-upf.service" ];
          
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          
          # Create and configure TUN device
          script = ''
            # Create TUN device if it doesn't exist
            if ! ip link show ${cfg.tun.device} &>/dev/null; then
              ip tuntap add name ${cfg.tun.device} mode tun
            fi
            
            # Configure IP address
            ip addr flush dev ${cfg.tun.device} 2>/dev/null || true
            ip addr add ${cfg.userPlane.gateway}/16 dev ${cfg.tun.device}
            ip link set ${cfg.tun.device} up
            
            # Enable IP forwarding
            sysctl -w net.ipv4.ip_forward=1
          '';
          
          # Cleanup on stop
          preStop = ''
            ip link del ${cfg.tun.device} 2>/dev/null || true
          '';
          
          path = [ pkgs.iproute2 pkgs.procps ];
        };
      })
      # 5G SA Network Functions
      (lib.mkIf (cfg.mode == "5g-sa" || cfg.mode == "both") {
        open5gs-nrf = mkNfService "nrf" "/etc/open5gs/nrf.yaml";
        open5gs-scp = mkNfService "scp" "/etc/open5gs/scp.yaml" // {
          after = [ "network.target" "open5gs-nrf.service" ];
        };
        open5gs-ausf = mkNfService "ausf" "/etc/open5gs/ausf.yaml";
        open5gs-udm = mkNfService "udm" "/etc/open5gs/udm.yaml";
        open5gs-udr = mkNfService "udr" "/etc/open5gs/udr.yaml";
        open5gs-pcf = mkNfService "pcf" "/etc/open5gs/pcf.yaml";
        open5gs-nssf = mkNfService "nssf" "/etc/open5gs/nssf.yaml";
        open5gs-bsf = mkNfService "bsf" "/etc/open5gs/bsf.yaml";
        open5gs-amf = mkNfService "amf" "/etc/open5gs/amf.yaml";
        open5gs-smf = mkNfService "smf" "/etc/open5gs/smf.yaml";
        open5gs-upf = mkNfService "upf" "/etc/open5gs/upf.yaml" // {
          after = [ "network.target" "open5gs-ogstun.service" "open5gs-nrf.service" ];
          requires = [ "open5gs-ogstun.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/open5gs-upfd -c /etc/open5gs/upf.yaml";
            Restart = "on-failure";
            RestartSec = "5s";
            # UPF needs root for TUN device access
            DynamicUser = false;
            User = "root";
          };
        };
      })
      
      # LTE Network Functions
      (lib.mkIf (cfg.mode == "lte" || cfg.mode == "both") {
        open5gs-mme = mkNfService "mme" "/etc/open5gs/mme.yaml";
        open5gs-hss = mkNfService "hss" "/etc/open5gs/hss.yaml";
        open5gs-sgwc = mkNfService "sgwc" "/etc/open5gs/sgwc.yaml";
        open5gs-sgwu = mkNfService "sgwu" "/etc/open5gs/sgwu.yaml";
        open5gs-pcrf = mkNfService "pcrf" "/etc/open5gs/pcrf.yaml";
      })
    ];
    
    # ─────────────────────────────────────────────────────────────────────────────
    # Firewall Configuration
    # ─────────────────────────────────────────────────────────────────────────────
    
    networking.firewall = {
      # Allow GTP-U (UDP 2152)
      allowedUDPPorts = [ 2152 ];
      
      # Allow SCTP for NGAP (5G) / S1AP (LTE)
      # NixOS doesn't have allowedSCTPPorts, so we use iptables directly
      extraCommands = ''
        ${pkgs.iptables}/bin/iptables -A INPUT -p sctp --dport ${toString cfg.ngap.port} -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -p sctp --dport 36412 -j ACCEPT
      '';
      extraStopCommands = ''
        ${pkgs.iptables}/bin/iptables -D INPUT -p sctp --dport ${toString cfg.ngap.port} -j ACCEPT || true
        ${pkgs.iptables}/bin/iptables -D INPUT -p sctp --dport 36412 -j ACCEPT || true
      '';
    };
  };
}

