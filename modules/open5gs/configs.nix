# Open5GS Configuration Generators
#
# This file generates YAML configurations for each Open5GS network function.
# Reference: https://open5gs.org/open5gs/docs/

{ lib, cfg, defaultAddresses }:

let
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
        ciphering_order = [ "NEA0" "NEA1" "NEA2" ];
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
  smf = {
    logger = mkLogger "smf";
    
    smf = {
      sbi = mkSbiWithScp (cfg.addresses.smf or defaultAddresses.smf) 7777;
      
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
      
      session = [{
        subnet = cfg.userPlane.subnet;
        gateway = cfg.userPlane.gateway;
      }];
      
      dns = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      
      mtu = 1400;
      
      ctf.enabled = "auto";
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
      
      session = [{
        subnet = cfg.userPlane.subnet;
        gateway = cfg.userPlane.gateway;
        dnn = cfg.userPlane.dnn;
        dev = cfg.tun.device;
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
  udm = {
    logger = mkLogger "udm";
    
    udm = {
      sbi = mkSbiWithScp (cfg.addresses.udm or defaultAddresses.udm) 7777;
    };
    
    hnet = [{
      id = 1;
      scheme = 1;
      key = "465b5ce8b199b49faa5f0a2ee238a6bc";  # Home network key (test value)
    }];
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
          address = cfg.addresses.mme or defaultAddresses.mme;
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
  hss = {
    logger = mkLogger "hss";
    db_uri = db_uri;
    
    hss = {
      freeDiameter = "/etc/open5gs/freeDiameter/hss.conf";
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
          address = cfg.addresses.sgwu or defaultAddresses.sgwu;
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
}

