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
    description = "Open5GS ${lib.toUpper name}d";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ] 
      ++ lib.optional cfg.mongodb.enable "mongodb.service"
      ++ lib.optional (name != "nrf") "open5gs-nrfd.service";
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
      LogsDirectory = "open5gs";  # Creates /var/log/open5gs with correct permissions
      
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
      
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.mongodb-ce;
        defaultText = lib.literalExpression "pkgs.mongodb-ce";
        description = "The MongoDB package to use. Use mongodb-ce for better binary cache support.";
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
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 5G SA External Interfaces (for connecting gNB)
    # ═══════════════════════════════════════════════════════════════════════════
    
    ngap = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.5";
        description = "NGAP (N2) interface address for gNB connection. Set to external IP for real gNB.";
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
        description = "GTP-U (N3) interface address for user plane. Set to external IP for real gNB.";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # 4G LTE External Interfaces (for connecting eNB)
    # ═══════════════════════════════════════════════════════════════════════════
    
    s1ap = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.2";
        description = "S1AP interface address for eNB connection (4G). Set to external IP for real eNB.";
      };
    };
    
    sgwuGtpu = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.6";
        description = "SGWU GTP-U interface address for 4G user plane. Set to external IP for real eNB.";
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
    # IMS/VoLTE Configuration (HSS Cx Interface)
    # ═══════════════════════════════════════════════════════════════════════════
    
    ims = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable IMS support for VoLTE/VoNR.
          This configures the HSS to expose the Cx interface for Kamailio I-CSCF/S-CSCF.
        '';
      };
      
      domain = lib.mkOption {
        type = lib.types.str;
        default = "ims.mnc001.mcc001.3gppnetwork.org";
        description = ''
          IMS domain name. Should follow 3GPP format:
          ims.mnc<MNC>.mcc<MCC>.3gppnetwork.org
        '';
      };
      
      icscf = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.30";
          description = "I-CSCF (Kamailio) IP address for Cx interface.";
        };
        
        port = lib.mkOption {
          type = lib.types.port;
          default = 3869;
          description = "I-CSCF Diameter port.";
        };
      };
      
      scscf = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.31";
          description = "S-CSCF (Kamailio) IP address for Cx interface.";
        };
        
        port = lib.mkOption {
          type = lib.types.port;
          default = 3870;
          description = "S-CSCF Diameter port.";
        };
      };
      
      smsc = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "sip:smsc.ims.mnc001.mcc001.3gppnetwork.org:7090";
        description = ''
          SMS over IMS (SMSoIP) SMSC SIP URI.
          If set, enables SMS over IMS in HSS.
        '';
      };
      
      # IMS User Plane Configuration
      dnn = lib.mkOption {
        type = lib.types.str;
        default = "ims";
        description = "Data Network Name for IMS signaling traffic.";
      };
      
      subnet = lib.mkOption {
        type = lib.types.str;
        default = "10.46.0.0/16";
        description = "UE IP address pool subnet for IMS PDU sessions.";
      };
      
      gateway = lib.mkOption {
        type = lib.types.str;
        default = "10.46.0.1";
        description = "Gateway IP for IMS traffic.";
      };
      
      tunDevice = lib.mkOption {
        type = lib.types.str;
        default = "ogstun2";
        description = "Name of the TUN device for IMS traffic.";
      };
    };
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SUPI Concealment (Home Network Key for 5G)
    # ═══════════════════════════════════════════════════════════════════════════
    
    hnet = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable SUPI concealment with Home Network keys.";
      };
      
      keys = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.int;
              description = "Home Network Public Key Identifier (1-255).";
            };
            scheme = lib.mkOption {
              type = lib.types.enum [ 1 2 ];
              default = 1;
              description = ''
                Protection scheme:
                - 1: Profile A (ECIES with X25519)
                - 2: Profile B (ECIES with secp256r1)
              '';
            };
            keyFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to the private key file. If null, a key will be auto-generated.";
            };
          };
        });
        default = [{
          id = 1;
          scheme = 1;
          keyFile = null;  # Auto-generate
        }];
        description = "List of Home Network keys for SUPI concealment.";
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
      package = cfg.mongodb.package;
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
            ${lib.optionalString cfg.ims.enable "ip saddr ${cfg.ims.subnet} masquerade"}
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
      
      # Generate HNET key entries
      # Note: mode 0644 allows the DynamicUser services to read the key
      # For production, consider using a dedicated user/group with stricter permissions
      hnetKeyEntries = lib.listToAttrs (map (key: {
        name = "open5gs/hnet/curve25519-${toString key.id}.key";
        value = {
          # If user provides a keyFile, use it; otherwise generate one
          source = if key.keyFile != null 
            then key.keyFile
            else pkgs.runCommand "hnet-key-${toString key.id}" {
              nativeBuildInputs = [ pkgs.openssl ];
            } ''
              # Generate X25519 private key for SUPI concealment
              openssl genpkey -algorithm X25519 -out $out
            '';
          mode = "0644";  # Readable by DynamicUser services
        };
      }) (lib.filter (k: k.scheme == 1) cfg.hnet.keys));
    in lib.mkMerge [
      # 5G SA specific components
      (lib.mkIf (cfg.mode == "5g-sa" || cfg.mode == "both") ({
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
      } // lib.optionalAttrs cfg.hnet.enable hnetKeyEntries))
      
      # LTE specific components
      (lib.mkIf (cfg.mode == "lte" || cfg.mode == "both") {
        "open5gs/mme.yaml".source = yamlFormat.generate "mme.yaml" configs.mme;
        "open5gs/hss.yaml".source = yamlFormat.generate "hss.yaml" configs.hss;
        "open5gs/sgwc.yaml".source = yamlFormat.generate "sgwc.yaml" configs.sgwc;
        "open5gs/sgwu.yaml".source = yamlFormat.generate "sgwu.yaml" configs.sgwu;
        "open5gs/pcrf.yaml".source = yamlFormat.generate "pcrf.yaml" configs.pcrf;
        
        # LTE-specific FreeDiameter configuration files (S6a interface)
        "open5gs/freeDiameter/mme.conf".text = configs.freeDiameterMme;
        "open5gs/freeDiameter/hss.conf".text = configs.freeDiameterHss;
      })
      
      # FreeDiameter configs for SMF/PCRF (Gx interface) - needed by both 5G-SA and LTE
      # These are shared and must only be defined once to avoid duplication
      {
        "open5gs/freeDiameter/smf.conf".text = configs.freeDiameterSmf;
        "open5gs/freeDiameter/pcrf.conf".text = configs.freeDiameterPcrf;
      }
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
          before = [ "open5gs-upfd.service" ];
          
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          
          # Create and configure TUN device(s)
          script = ''
            # Create primary TUN device if it doesn't exist
            if ! ip link show ${cfg.tun.device} &>/dev/null; then
              ip tuntap add name ${cfg.tun.device} mode tun
            fi
            
            # Configure IP address for primary TUN
            ip addr flush dev ${cfg.tun.device} 2>/dev/null || true
            ip addr add ${cfg.userPlane.gateway}/16 dev ${cfg.tun.device}
            ip link set ${cfg.tun.device} up
            
            ${lib.optionalString cfg.ims.enable ''
            # Create IMS TUN device if it doesn't exist
            if ! ip link show ${cfg.ims.tunDevice} &>/dev/null; then
              ip tuntap add name ${cfg.ims.tunDevice} mode tun
            fi
            
            # Configure IP address for IMS TUN
            ip addr flush dev ${cfg.ims.tunDevice} 2>/dev/null || true
            ip addr add ${cfg.ims.gateway}/16 dev ${cfg.ims.tunDevice}
            ip link set ${cfg.ims.tunDevice} up
            ''}
            
            # Enable IP forwarding
            sysctl -w net.ipv4.ip_forward=1
          '';
          
          # Cleanup on stop
          preStop = ''
            ip link del ${cfg.tun.device} 2>/dev/null || true
            ${lib.optionalString cfg.ims.enable ''
            ip link del ${cfg.ims.tunDevice} 2>/dev/null || true
            ''}
          '';
          
          path = [ pkgs.iproute2 pkgs.procps ];
        };
      })
      # 5G SA Network Functions
      (lib.mkIf (cfg.mode == "5g-sa" || cfg.mode == "both") {
        open5gs-nrfd = mkNfService "nrf" "/etc/open5gs/nrf.yaml";
        open5gs-scpd = mkNfService "scp" "/etc/open5gs/scp.yaml" // {
          after = [ "network.target" "open5gs-nrfd.service" ];
        };
        open5gs-ausfd = mkNfService "ausf" "/etc/open5gs/ausf.yaml";
        open5gs-udmd = mkNfService "udm" "/etc/open5gs/udm.yaml";
        open5gs-udrd = mkNfService "udr" "/etc/open5gs/udr.yaml";
        open5gs-pcfd = mkNfService "pcf" "/etc/open5gs/pcf.yaml";
        open5gs-nssfd = mkNfService "nssf" "/etc/open5gs/nssf.yaml";
        open5gs-bsfd = mkNfService "bsf" "/etc/open5gs/bsf.yaml";
        open5gs-amfd = mkNfService "amf" "/etc/open5gs/amf.yaml";
        open5gs-smfd = mkNfService "smf" "/etc/open5gs/smf.yaml";
        open5gs-upfd = mkNfService "upf" "/etc/open5gs/upf.yaml" // {
          after = [ "network.target" "open5gs-ogstun.service" "open5gs-nrfd.service" ];
          requires = [ "open5gs-ogstun.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/open5gs-upfd -c /etc/open5gs/upf.yaml";
            Restart = "on-failure";
            RestartSec = "5s";
            # UPF needs root for TUN device access
            DynamicUser = false;
            User = "root";
            LogsDirectory = "open5gs";
          };
        };
      })
      
      # LTE Network Functions
      (lib.mkIf (cfg.mode == "lte" || cfg.mode == "both") {
        open5gs-mmed = mkNfService "mme" "/etc/open5gs/mme.yaml";
        open5gs-hssd = mkNfService "hss" "/etc/open5gs/hss.yaml";
        open5gs-sgwcd = mkNfService "sgwc" "/etc/open5gs/sgwc.yaml";
        open5gs-sgwud = mkNfService "sgwu" "/etc/open5gs/sgwu.yaml";
        open5gs-pcrfd = mkNfService "pcrf" "/etc/open5gs/pcrf.yaml";
      })
    ];
    
    # ─────────────────────────────────────────────────────────────────────────────
    # Firewall Configuration
    # ─────────────────────────────────────────────────────────────────────────────
    
    networking.firewall = {
      # Allow GTP-U (UDP 2152)
      allowedUDPPorts = [ 2152 ];
      
      # Allow SCTP for NGAP (5G) / S1AP (LTE)
      # NixOS doesn't have allowedSCTPPorts, so we handle it manually
      # Use nftables syntax if nftables is enabled, otherwise use iptables
      extraInputRules = lib.mkIf config.networking.nftables.enable ''
        sctp dport ${toString cfg.ngap.port} accept comment "Open5GS NGAP (5G)"
        sctp dport 36412 accept comment "Open5GS S1AP (LTE)"
      '';
      
      # Fallback to iptables if nftables is not enabled
      extraCommands = lib.mkIf (!config.networking.nftables.enable) ''
        ${pkgs.iptables}/bin/iptables -A INPUT -p sctp --dport ${toString cfg.ngap.port} -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A INPUT -p sctp --dport 36412 -j ACCEPT
      '';
      extraStopCommands = lib.mkIf (!config.networking.nftables.enable) ''
        ${pkgs.iptables}/bin/iptables -D INPUT -p sctp --dport ${toString cfg.ngap.port} -j ACCEPT || true
        ${pkgs.iptables}/bin/iptables -D INPUT -p sctp --dport 36412 -j ACCEPT || true
      '';
    };
  };
}

