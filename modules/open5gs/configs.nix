# Open5GS Configuration Generators
#
# This file generates YAML configurations for each Open5GS network function.
# Reference: https://open5gs.org/open5gs/docs/

{ lib, cfg, defaultAddresses }:

let
  # Get the package path for FreeDiameter extensions and TLS certs
  pkgPath = cfg.package;
  # Helper to create SBI configuration with SCP-based indirect communication
  # This is the recommended pattern for Open5GS 5G SA
  mkSbiWithScp = addr: port: {
    server = [{ address = addr; inherit port; }];
    client = {
      scp = [{ uri = "http://${defaultAddresses.scp}:7777"; }];
    };
  };
  
  # Helper for NRF client (only used by SCP)
  mkSbiWithNrf = addr: port: {
    server = [{ address = addr; inherit port; }];
    client = {
      nrf = [{ uri = "http://${defaultAddresses.nrf}:7777"; }];
    };
  };
  
  # Logger configuration generator - each NF gets its own log file
  mkLogger = name: {
    file = "/var/log/open5gs/${name}.log";
    level = "info";
  };
  
  # MongoDB database configuration
  db_uri = cfg.mongodb.uri;
  
in {
  # ═══════════════════════════════════════════════════════════════════════════════
  # 5G SA Core Network Functions
  # ═══════════════════════════════════════════════════════════════════════════════
  
  # NRF - NF Repository Function
  # Central registry for all network functions
  nrf = {
    logger = mkLogger "nrf";
    db_uri = db_uri;
    
    nrf = {
      sbi = {
        server = [{
          address = cfg.addresses.nrf or defaultAddresses.nrf;
          port = 7777;
        }];
      };
    };
  };
  
  # SCP - Service Communication Proxy
  # Routes messages between network functions
  # SCP connects directly to NRF (not via SCP itself)
  scp = {
    logger = mkLogger "scp";
    
    scp = {
      sbi = mkSbiWithNrf (cfg.addresses.scp or defaultAddresses.scp) 7777;
    };
  };
  
  # AMF - Access and Mobility Management Function
  # Handles UE registration, mobility, and connection management
  # Reference: https://github.com/open5gs/open5gs/blob/main/configs/open5gs/amf.yaml.in
  amf = {
    logger = mkLogger "amf";
    
    amf = {
      sbi = {
        server = [{
          address = cfg.addresses.amf or defaultAddresses.amf;
          port = 7777;
        }];
        client = {
          # Indirect Communication by Delegating to SCP
          scp = [{
            uri = "http://${defaultAddresses.scp}:7777";
          }];
        };
      };
      
      ngap = {
        server = [{
          address = cfg.ngap.address;
        }];
      };
      
      metrics = {
        server = [{
          address = cfg.addresses.amf or defaultAddresses.amf;
          port = 9090;
        }];
      };
      
      guami = [{
        plmn_id = {
          mcc = cfg.plmn.mcc;
          mnc = cfg.plmn.mnc;
        };
        amf_id = {
          region = 2;
          set = 1;
        };
      }];
      
      tai = [{
        plmn_id = {
          mcc = cfg.plmn.mcc;
          mnc = cfg.plmn.mnc;
        };
        tac = cfg.tac;
      }];
      
      plmn_support = [{
        plmn_id = {
          mcc = cfg.plmn.mcc;
          mnc = cfg.plmn.mnc;
        };
        s_nssai = [{
          sst = 1;  # eMBB (enhanced Mobile Broadband)
        }];
      }];
      
      security = {
        integrity_order = [ "NIA2" "NIA1" "NIA0" ];
        ciphering_order = [ "NEA2" "NEA1" "NEA0" ];
      };
      
      network_name = {
        full = cfg.networkName;
        short = cfg.networkName;
      };
      
      amf_name = "open5gs-amf0";
      
      time = {
        t3512 = { value = 540; };  # Periodic registration update timer (9 minutes)
      };
    };
  };
  
  # SMF - Session Management Function
  # Manages PDU sessions for data connectivity
  # In LTE mode, SMF also acts as PGW-c and uses Diameter (Gx) to connect to PCRF
  smf = {
    logger = mkLogger "smf";
    
    smf = {
      sbi = mkSbiWithScp (cfg.addresses.smf or defaultAddresses.smf) 7777;
      
      # FreeDiameter for Gx interface (SMF/PGW-c <-> PCRF) - used in LTE mode
      freeDiameter = "/etc/open5gs/freeDiameter/smf.conf";
      
      pfcp = {
        server = [{
          address = cfg.addresses.smf or defaultAddresses.smf;
        }];
        client = {
          upf = [{
            address = cfg.addresses.upf or defaultAddresses.upf;
          }];
        };
      };
      
      gtpc = {
        server = [{
          address = cfg.addresses.smf or defaultAddresses.smf;
        }];
      };
      
      gtpu = {
        server = [{
          address = cfg.addresses.smf or defaultAddresses.smf;
        }];
      };
      
      metrics = {
        server = [{
          address = cfg.addresses.smf or defaultAddresses.smf;
          port = 9091;
        }];
      };
      
      # Internet DNN session, plus IMS DNN session when IMS is enabled
      session = [{
        subnet = cfg.userPlane.subnet;
        gateway = cfg.userPlane.gateway;
      }] ++ lib.optionals cfg.ims.enable [{
        subnet = cfg.ims.subnet;
        gateway = cfg.ims.gateway;
      }];
      
      dns = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      
      mtu = 1400;
      
      ctf.enabled = "auto";
    } // lib.optionalAttrs cfg.ims.enable {
      # P-CSCF addresses for PCO (Protocol Configuration Options)
      # These are advertised to UEs during PDU session establishment for IMS discovery
      p-cscf = if cfg.ims.pcscf.pco != [] 
               then cfg.ims.pcscf.pco 
               else [ cfg.ims.pcscf.address ];
    };
  };
  
  # UPF - User Plane Function  
  # Handles user data traffic
  upf = {
    logger = mkLogger "upf";
    
    upf = {
      pfcp = {
        server = [{
          address = cfg.addresses.upf or defaultAddresses.upf;
        }];
      };
      
      gtpu = {
        server = [{
          address = cfg.gtpu.address;
        }];
      };
      
      # Internet DNN session, plus IMS DNN session when IMS is enabled
      session = [{
        subnet = cfg.userPlane.subnet;
        gateway = cfg.userPlane.gateway;
        dnn = cfg.userPlane.dnn;
        dev = cfg.tun.device;
      }] ++ lib.optionals cfg.ims.enable [{
        subnet = cfg.ims.subnet;
        gateway = cfg.ims.gateway;
        dnn = cfg.ims.dnn;
        dev = cfg.ims.tunDevice;
      }];
      
      metrics = {
        server = [{
          address = cfg.addresses.upf or defaultAddresses.upf;
          port = 9092;
        }];
      };
    };
  };
  
  # AUSF - Authentication Server Function
  ausf = {
    logger = mkLogger "ausf";
    
    ausf = {
      sbi = mkSbiWithScp (cfg.addresses.ausf or defaultAddresses.ausf) 7777;
    };
  };
  
  # UDM - Unified Data Management
  # SUPI concealment uses Home Network keys for privacy protection
  udm = {
    logger = mkLogger "udm";
    
    udm = {
      sbi = mkSbiWithScp (cfg.addresses.udm or defaultAddresses.udm) 7777;
    } // lib.optionalAttrs (cfg.hnet.enable or true) {
      hnet = map (k: {
        id = k.id;
        scheme = k.scheme;
        key = "/etc/open5gs/hnet/curve25519-${toString k.id}.key";
      }) (cfg.hnet.keys or [{ id = 1; scheme = 1; }]);
    };
    # Home Network keys for SUPI concealment
    # Reference: https://open5gs.org/open5gs/docs/guide/01-quickstart/#supi-concealment
  };
  
  # UDR - Unified Data Repository
  # UDR is the only 5G NF that directly accesses the database
  udr = {
    logger = mkLogger "udr";
    db_uri = db_uri;
    
    udr = {
      sbi = mkSbiWithScp (cfg.addresses.udr or defaultAddresses.udr) 7777;
    };
  };
  
  # PCF - Policy Control Function
  pcf = {
    logger = mkLogger "pcf";
    db_uri = db_uri;
    
    pcf = {
      sbi = mkSbiWithScp (cfg.addresses.pcf or defaultAddresses.pcf) 7777;
    };
  };
  
  # NSSF - Network Slice Selection Function
  # Reference: https://github.com/open5gs/open5gs/blob/main/configs/open5gs/nssf.yaml.in
  nssf = {
    logger = mkLogger "nssf";
    
    nssf = {
      sbi = {
        server = [{
          address = cfg.addresses.nssf or defaultAddresses.nssf;
          port = 7777;
        }];
        client = {
          scp = [{
            uri = "http://${defaultAddresses.scp}:7777";
          }];
          # Network Slice Instance - points to NRF for each slice
          nsi = [{
            uri = "http://${defaultAddresses.nrf}:7777";
            s_nssai = {
              sst = 1;  # eMBB slice
            };
          }];
        };
      };
    };
  };
  
  # BSF - Binding Support Function
  bsf = {
    logger = mkLogger "bsf";
    db_uri = db_uri;
    
    bsf = {
      sbi = mkSbiWithScp (cfg.addresses.bsf or defaultAddresses.bsf) 7777;
    };
  };
  
  # ═══════════════════════════════════════════════════════════════════════════════
  # LTE/4G Core Network Functions
  # ═══════════════════════════════════════════════════════════════════════════════
  
  # MME - Mobility Management Entity
  mme = {
    logger = mkLogger "mme";
    db_uri = db_uri;
    
    mme = {
      freeDiameter = "/etc/open5gs/freeDiameter/mme.conf";
      
      s1ap = {
        server = [{
          address = cfg.s1ap.address;  # External IP for eNB connection
        }];
      };
      
      gtpc = {
        server = [{
          address = cfg.addresses.mme or defaultAddresses.mme;
        }];
        client = {
          sgwc = [{
            address = cfg.addresses.sgwc or defaultAddresses.sgwc;
          }];
          smf = [{
            address = cfg.addresses.smf or defaultAddresses.smf;
          }];
        };
      };
      
      metrics = {
        server = [{
          address = cfg.addresses.mme or defaultAddresses.mme;
          port = 9090;
        }];
      };
      
      gummei = [{
        plmn_id = {
          mcc = cfg.plmn.mcc;
          mnc = cfg.plmn.mnc;
        };
        mme_gid = 2;
        mme_code = 1;
      }];
      
      tai = [{
        plmn_id = {
          mcc = cfg.plmn.mcc;
          mnc = cfg.plmn.mnc;
        };
        tac = cfg.tac;
      }];
      
      security = {
        integrity_order = [ "EIA2" "EIA1" "EIA0" ];
        ciphering_order = [ "EEA0" "EEA1" "EEA2" ];
      };
      
      network_name = {
        full = cfg.networkName;
        short = cfg.networkName;
      };
      
      mme_name = "open5gs-mme0";
    };
  };
  
  # HSS - Home Subscriber Server
  # When IMS is enabled, HSS also serves Cx interface for I-CSCF/S-CSCF
  hss = {
    logger = mkLogger "hss";
    db_uri = db_uri;
    
    hss = {
      freeDiameter = "/etc/open5gs/freeDiameter/hss.conf";
    } // lib.optionalAttrs cfg.ims.enable {
      default_scscf = cfg.ims.defaultScscf;
    } // lib.optionalAttrs (cfg.ims.enable && cfg.ims.smsc != null) {
      sms_over_ims = cfg.ims.smsc;
    };
  };
  
  # SGWC - Serving Gateway Control Plane
  sgwc = {
    logger = mkLogger "sgwc";
    
    sgwc = {
      gtpc = {
        server = [{
          address = cfg.addresses.sgwc or defaultAddresses.sgwc;
        }];
        client = {
          sgwu = [{
            address = cfg.addresses.sgwu or defaultAddresses.sgwu;
          }];
        };
      };
      
      pfcp = {
        server = [{
          address = cfg.addresses.sgwc or defaultAddresses.sgwc;
        }];
        client = {
          sgwu = [{
            address = cfg.addresses.sgwu or defaultAddresses.sgwu;
          }];
        };
      };
    };
  };
  
  # SGWU - Serving Gateway User Plane
  sgwu = {
    logger = mkLogger "sgwu";
    
    sgwu = {
      pfcp = {
        server = [{
          address = cfg.addresses.sgwu or defaultAddresses.sgwu;
        }];
      };
      
      gtpu = {
        server = [{
          address = cfg.sgwuGtpu.address;  # External IP for eNB user plane
        }];
      };
    };
  };
  
  # PCRF - Policy and Charging Rules Function
  pcrf = {
    logger = mkLogger "pcrf";
    db_uri = db_uri;
    
    pcrf = {
      freeDiameter = "/etc/open5gs/freeDiameter/pcrf.conf";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════════
  # FreeDiameter Configuration Files (for LTE Diameter protocol)
  # ═══════════════════════════════════════════════════════════════════════════════
  # 
  # FreeDiameter is used for:
  #   - S6a interface: MME <-> HSS (authentication, subscriber data)
  #   - Gx interface:  SMF/PGW-c <-> PCRF (policy, QoS rules)
  #
  # Reference: https://lantian.pub/en/article/modify-computer/legal-lte-network-at-home-with-open5gs.lantian/

  # MME FreeDiameter configuration (connects to HSS via S6a)
  # Uses localdomain to match the default Open5GS TLS certificates
  freeDiameterMme = ''
    # FreeDiameter configuration for MME
    Identity = "mme.localdomain";
    Realm = "localdomain";

    # Listen on MME address
    ListenOn = "${cfg.addresses.mme or defaultAddresses.mme}";

    # TLS credentials from Open5GS package
    TLS_Cred = "${pkgPath}/etc/open5gs/tls/mme.crt", "${pkgPath}/etc/open5gs/tls/mme.key";
    TLS_CA = "${pkgPath}/etc/open5gs/tls/ca.crt";

    # Disable relaying - we only handle our own messages
    NoRelay;

    # Load FreeDiameter extensions
    LoadExtension = "${pkgPath}/lib/freeDiameter/dbg_msg_dumps.fdx" : "0x8888";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_rfc5777.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_mip6i.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nasreq.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nas_mipv6.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca_3gpp.fdx";

    # Connect to HSS (S6a interface) - No_TLS for local testing
    ConnectPeer = "hss.localdomain" { ConnectTo = "${cfg.addresses.hss or defaultAddresses.hss}"; No_TLS; };
  '';

  # HSS FreeDiameter configuration (accepts connections from MME, and optionally I-CSCF/S-CSCF for IMS)
  # When IMS is enabled, HSS provides both S6a (MME) and Cx (I-CSCF/S-CSCF) interfaces
  # Uses localdomain to match the default Open5GS TLS certificates
  freeDiameterHss = let
    # Cx interface peers (I-CSCF and S-CSCF) - only when IMS is enabled
    # IMS components should also use localdomain for consistency
    cxPeers = lib.optionalString cfg.ims.enable ''
      # Cx interface for IMS - I-CSCF (Interrogating-CSCF)
      ConnectPeer = "icscf.localdomain" { ConnectTo = "${cfg.ims.icscf.address}"; Port = ${toString cfg.ims.icscf.port}; No_TLS; };
      # Cx interface for IMS - S-CSCF (Serving-CSCF)
      ConnectPeer = "scscf.localdomain" { ConnectTo = "${cfg.ims.scscf.address}"; Port = ${toString cfg.ims.scscf.port}; No_TLS; };
    '';
  in ''
    # FreeDiameter configuration for HSS
    # Supports S6a interface (MME) and optionally Cx interface (I-CSCF/S-CSCF for IMS)
    Identity = "hss.localdomain";
    Realm = "localdomain";

    # Listen on HSS address
    ListenOn = "${cfg.addresses.hss or defaultAddresses.hss}";

    # TLS credentials from Open5GS package
    TLS_Cred = "${pkgPath}/etc/open5gs/tls/hss.crt", "${pkgPath}/etc/open5gs/tls/hss.key";
    TLS_CA = "${pkgPath}/etc/open5gs/tls/ca.crt";

    # Disable relaying
    NoRelay;

    # Load FreeDiameter extensions
    LoadExtension = "${pkgPath}/lib/freeDiameter/dbg_msg_dumps.fdx" : "0x8888";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_rfc5777.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_mip6i.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nasreq.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nas_mipv6.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca_3gpp.fdx";

    # S6a interface - HSS accepts connection from MME
    ConnectPeer = "mme.localdomain" { ConnectTo = "${cfg.addresses.mme or defaultAddresses.mme}"; No_TLS; };
    ${cxPeers}
  '';

  # SMF FreeDiameter configuration (connects to PCRF via Gx, used in LTE mode as PGW-c)
  freeDiameterSmf = ''
    # FreeDiameter configuration for SMF (PGW-c in LTE)
    Identity = "smf.localdomain";
    Realm = "localdomain";

    # Listen on SMF address
    ListenOn = "${cfg.addresses.smf or defaultAddresses.smf}";

    # TLS credentials from Open5GS package
    TLS_Cred = "${pkgPath}/etc/open5gs/tls/smf.crt", "${pkgPath}/etc/open5gs/tls/smf.key";
    TLS_CA = "${pkgPath}/etc/open5gs/tls/ca.crt";

    # Disable relaying
    NoRelay;

    # Load FreeDiameter extensions
    LoadExtension = "${pkgPath}/lib/freeDiameter/dbg_msg_dumps.fdx" : "0x8888";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_rfc5777.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_mip6i.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nasreq.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nas_mipv6.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca_3gpp.fdx";

    # Connect to PCRF (Gx interface) - No_TLS for local testing
    ConnectPeer = "pcrf.localdomain" { ConnectTo = "${cfg.addresses.pcrf or defaultAddresses.pcrf}"; No_TLS; };
  '';

  # PCRF FreeDiameter configuration (accepts connections from SMF/PGW-c, and P-CSCF for IMS)
  freeDiameterPcrf = let
    # Rx interface peer (P-CSCF) - only when IMS is enabled
    rxPeer = lib.optionalString cfg.ims.enable ''
      # Rx interface for IMS - P-CSCF (Proxy-CSCF)
      ConnectPeer = "pcscf.localdomain" { ConnectTo = "${cfg.ims.pcscf.address}"; Port = ${toString cfg.ims.pcscf.port}; No_TLS; };
    '';
  in ''
    # FreeDiameter configuration for PCRF
    # Supports Gx interface (SMF/PGW-c) and optionally Rx interface (P-CSCF for IMS)
    Identity = "pcrf.localdomain";
    Realm = "localdomain";

    # Listen on PCRF address
    ListenOn = "${cfg.addresses.pcrf or defaultAddresses.pcrf}";

    # TLS credentials from Open5GS package
    TLS_Cred = "${pkgPath}/etc/open5gs/tls/pcrf.crt", "${pkgPath}/etc/open5gs/tls/pcrf.key";
    TLS_CA = "${pkgPath}/etc/open5gs/tls/ca.crt";

    # Disable relaying
    NoRelay;

    # Load FreeDiameter extensions
    LoadExtension = "${pkgPath}/lib/freeDiameter/dbg_msg_dumps.fdx" : "0x8888";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_rfc5777.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_mip6i.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nasreq.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_nas_mipv6.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca.fdx";
    LoadExtension = "${pkgPath}/lib/freeDiameter/dict_dcca_3gpp.fdx";

    # Gx interface - PCRF accepts connection from SMF - No_TLS for local testing
    ConnectPeer = "smf.localdomain" { ConnectTo = "${cfg.addresses.smf or defaultAddresses.smf}"; No_TLS; };
    ${rxPeer}
  '';
}

