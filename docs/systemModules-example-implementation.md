# SystemModules Example Implementation

## Overview

This document provides a complete example of implementing a new service following the standardized architecture patterns. We'll use a hypothetical "example-service" to demonstrate all aspects of the new pattern.

## Step-by-Step Implementation

### 1. Add Packages to Central Registry

First, add service packages to `systemModules/packages.nix`:

```nix
# systemModules/packages.nix - Add new service packages
rec {
  # ... existing packages ...
  
  # Example service packages
  exampleService = with pkgs; [
    example-service-binary  # Main service binary
    example-service-cli     # Command-line interface
  ];
  
  # Example service utilities (for VM deployments)
  exampleServiceUtils = with pkgs; [
    example-service-admin   # Admin tools
    example-service-debug   # Debugging utilities
    postgresql             # If service needs database tools
  ];
  
  # ... existing exports ...
} // {
  inherit base monitoring ... exampleService exampleServiceUtils;
  inherit getServicePackages getCombinedPackages;
}
```

### 2. Create SystemModule

Create `systemModules/example-service.nix`:

```nix
# Example Service Module  
# Provides example web service for homelab demonstrations
{ config, lib, pkgs, ... }:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.exampleService;
in {
  options.homelab.exampleService = {
    enable = mkEnableOption "Example web service for homelab demonstrations";
    
    # Standard deployment options
    deploymentType = mkOption {
      type = types.enum [ "vm" "container" "hybrid" ];
      default = "vm";
      description = "Deployment type - affects resource allocation and feature set";
    };
    
    resourceProfile = mkOption {
      type = types.enum [ "minimal" "standard" "high" ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };
    
    # Service-specific options with intelligent defaults
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Example service HTTP port";
    };
    
    domain = mkOption {
      type = types.str;
      default = "example.homelab.local";
      description = "Service domain name";
    };
    
    # Database configuration (VM only by default)
    database = {
      enable = mkOption {
        type = types.bool;
        default = cfg.deploymentType == "vm" && cfg.resourceProfile != "minimal";
        description = "Enable PostgreSQL database";
      };
      
      name = mkOption {
        type = types.str;
        default = "exampleservice";
        description = "Database name";
      };
    };
    
    # Advanced features (high resource profile only)
    advancedFeatures = {
      enable = mkOption {
        type = types.bool;
        default = cfg.resourceProfile == "high";
        description = "Enable advanced features";
      };
      
      caching = mkOption {
        type = types.bool;
        default = cfg.advancedFeatures.enable;
        description = "Enable Redis caching";
      };
    };
    
    # Retention settings based on deployment type
    dataRetention = mkOption {
      type = types.str;
      default = 
        if cfg.deploymentType == "container" then "30d"
        else if cfg.resourceProfile == "minimal" then "90d"
        else "365d";
      description = "Data retention period";
    };
  };
  
  config = mkMerge [
    # Base service configuration
    (mkIf cfg.enable {
      # Core service setup
      services.example-service = {
        enable = true;
        port = cfg.port;
        domain = cfg.domain;
        dataRetentionDays = cfg.dataRetention;
      };
      
      # User and group
      users.users.example-service = {
        isSystemUser = true;
        group = "example-service";
        home = "/var/lib/example-service";
        createHome = true;
      };
      users.groups.example-service = {};
      
      # Firewall
      networking.firewall.allowedTCPPorts = [ cfg.port ];
      
      # Packages from centralized registry
      environment.systemPackages = servicePackages.exampleService ++
        (optionals (cfg.deploymentType == "vm") servicePackages.exampleServiceUtils) ++
        servicePackages.base;
      
      # SOPS integration
      sops.secrets = {
        "example-service/api-key" = {
          owner = "example-service";
          group = "example-service";
          mode = "0600";
        };
      };
      
      # Service configuration template
      sops.templates."example-service-config" = {
        content = ''
          [service]
          port = ${toString cfg.port}
          domain = ${cfg.domain}
          api_key = ${config.sops.placeholder."example-service/api-key"}
          
          [retention]
          data_retention = ${cfg.dataRetention}
        '';
        owner = "example-service";
        group = "example-service";
      };
      
      # Basic monitoring integration
      services.prometheus.exporters.example-service = mkIf config.services.prometheus.enable {
        enable = true;
        port = cfg.port + 1;  # Metrics on port + 1
      };
    })
    
    # Database configuration (VM/high-resource only)
    (mkIf (cfg.enable && cfg.database.enable) {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [
          {
            name = "example-service";
            ensurePermissions = {
              "DATABASE ${cfg.database.name}" = "ALL PRIVILEGES";
            };
          }
        ];
      };
      
      # Database password via SOPS
      sops.secrets."example-service/db-password" = {
        owner = "example-service";
        group = "example-service";
      };
    })
    
    # Advanced features (high resource profile)
    (mkIf (cfg.enable && cfg.advancedFeatures.enable) {
      # Redis caching
      services.redis.servers.example-service = mkIf cfg.advancedFeatures.caching {
        enable = true;
        port = 6379;
        bind = "127.0.0.1";
      };
      
      # Enhanced monitoring
      services.prometheus.exporters.redis = mkIf cfg.advancedFeatures.caching {
        enable = true;
        port = 9121;
      };
    })
    
    # VM-specific configuration
    (mkIf (cfg.enable && cfg.deploymentType == "vm") {
      # VM performance tuning
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
      };
      
      # Log rotation for VM deployments
      services.logrotate.settings."example-service" = {
        files = [ "/var/log/example-service/*.log" ];
        frequency = "daily";
        rotate = 30;
        compress = true;
        delaycompress = true;
      };
    })
    
    # Container-specific configuration
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      # Container optimizations
      boot.isContainer = true;
      
      # Reduced logging for containers
      services.example-service.logLevel = "warn";
      
      # Container resource limits
      systemd.services.example-service.serviceConfig = {
        MemoryLimit = "512M";
        CPUQuota = "50%";
      };
    })
  ];
}
```

### 3. Create VM Host Configuration

Create `hosts/example-service/default.nix`:

```nix
# Example Service VM Host Configuration  
# Full-featured deployment with database and advanced features
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/example-service.nix
    ../../systemModules/sops.nix
  ];
  
  # System identification
  networking.hostName = systemSettings.hostname;
  
  # Enable example service with VM-optimized settings
  homelab.exampleService = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";
    
    # VM-specific overrides only
    domain = "example.homelab.local";
    
    # Enable all features for VM deployment
    database.enable = true;
    advancedFeatures = {
      enable = true;
      caching = true;
    };
  };
  
  # Additional VM-specific configuration
  networking.firewall = {
    allowedTCPPorts = [
      8080  # Example service (configured by module)
      8081  # Metrics (configured by module)
    ];
    
    # Allow access from homelab network
    extraCommands = ''
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 8080 -j ACCEPT
    '';
  };
  
  # SOPS integration
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
```

### 4. Create Container Host Configuration  

Create `hosts/lxc-example-service/default.nix`:

```nix
# Example Service LXC Container Configuration
# Resource-efficient deployment for testing/development
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../lxc-base/default.nix
    ../../systemModules/example-service.nix
    ../../systemModules/sops.nix
  ];
  
  # System identification
  networking.hostName = systemSettings.hostname;
  
  # Enable example service optimized for container deployment
  homelab.exampleService = {
    enable = true;
    deploymentType = "container";
    resourceProfile = "minimal";
    
    # Container-specific overrides only
    domain = "example.homelab.local";
    
    # Minimal configuration for container
    database.enable = false;  # Use external database
    advancedFeatures.enable = false;  # Disable advanced features
    dataRetention = "14d";  # Shorter retention for testing
  };
  
  # Container networking
  networking.firewall.allowedTCPPorts = [
    22    # SSH (from lxc-base)
    8080  # Example service
  ];
  
  # SOPS integration
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
```

### 5. Add to Flake Configuration

Update `flake.nix` to include the new hosts:

```nix
# flake.nix - Add example service configurations
nixosConfigurations = {
  # ... existing configurations ...
  
  # Example Service VM
  example-service = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs outputs;
      userSettings = baseUserSettings;
      systemSettings = systemSettings // {
        hostname = "example-service";
        profile = "server";
      };
    };
    modules = [ ./hosts/example-service ];
  };
  
  # Example Service Container
  lxc-example-service = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs outputs;
      userSettings = baseUserSettings;
      systemSettings = systemSettings // {
        hostname = "lxc-example-service";
        profile = "server";
      };
    };
    modules = [ ./hosts/lxc-example-service ];
  };
};
```

### 6. Create Service Documentation

Create `docs/example-service-setup.md`:

```markdown
# Example Service Setup Guide

## Overview

Example Service provides web-based demonstration capabilities for the homelab. It showcases the standardized systemModule architecture patterns with intelligent deployment optimization.

## Features

- **Web Interface**: HTTP API and dashboard
- **Database Integration**: PostgreSQL (VM deployments)
- **Caching**: Redis support (high-resource profiles)
- **Monitoring**: Prometheus metrics integration
- **Flexible Deployment**: VM and container support

## Architecture

[Include architecture diagram and explanation]

## Configuration

### VM Deployment
```nix
homelab.exampleService = {
  enable = true;
  deploymentType = "vm";
  resourceProfile = "standard";
  domain = "example.homelab.local";
};
```

### Container Deployment
```nix
homelab.exampleService = {
  enable = true;
  deploymentType = "container";
  resourceProfile = "minimal";
};
```

## Deployment

[Include deployment procedures]

## Troubleshooting

[Include common issues and solutions]
```

### 7. Update Infrastructure Registry

Add to `docs/infrastructure-registry.md`:

```markdown
## Example Service Deployments

| Service | Hostname | VM/CT ID | IP Address | Cores | RAM | Disk | Ports | Status | Access |
|---------|----------|----------|------------|-------|-----|------|-------|---------|--------|
| **Example Service** | example-service | 109 | `10.0.0.TBD` | 2 | 4GB | 50GB | 8080,8081 | `planned` | `http://example.homelab.local:8080` |
| **Example Service (LXC)** | lxc-example-service | 209 | `10.0.0.TBD` | 1 | 2GB | 20GB | 8080 | `planned` | `http://example.homelab.local:8080` |

**Deployment Commands**:
```bash
# Example Service VM
nixos-rebuild switch --target-host sandmhan@10.0.0.TBD --flake .#example-service --sudo

# Example Service Container  
nixos-rebuild switch --target-host monitor@10.0.0.TBD --flake .#lxc-example-service --sudo
```
```

### 8. Add SOPS Secrets

Update `.sops.yaml`:

```yaml
creation_rules:
  # ... existing rules ...
  
  # Example service secrets
  - path_regex: secrets/example-service/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_age
      - *example_service_key  # Add host key
```

Create secret file:

```bash
# Create example service secrets
cat > secrets/example-service/secrets.yaml << EOF
api-key: $(openssl rand -base64 32)
db-password: $(openssl rand -base64 24)
EOF

sops -e -i secrets/example-service/secrets.yaml
```

## Testing the Implementation

### Build Validation

```bash
# Test VM configuration builds correctly
nix build --dry-run .#nixosConfigurations.example-service.config.system.build.toplevel

# Test container configuration builds correctly  
nix build --dry-run .#nixosConfigurations.lxc-example-service.config.system.build.toplevel
```

### Deployment Testing

```bash
# Create and deploy VM
qmrestore /var/lib/vz/dump/base-image.vma.zst 109 --storage local-zfs
qm set 109 --cores 2 --memory 4096 --name example-service
qm start 109
nixos-rebuild switch --target-host sandmhan@10.0.0.TBD --flake .#example-service --sudo

# Verify service health
curl http://10.0.0.TBD:8080/health
curl http://10.0.0.TBD:8081/metrics
```

### Monitoring Integration

```bash
# Verify Prometheus discovers service
curl http://monitor.homelab.local:9090/api/v1/query?query=up{job="example-service"}

# Check in Grafana
# Navigate to: http://grafana.homelab.local:3000
```

## Key Benefits Demonstrated

This implementation showcases:

✅ **Zero Configuration Duplication**: All logic in systemModule with intelligent defaults  
✅ **Automatic Environment Optimization**: Container gets minimal config, VM gets full features  
✅ **Centralized Package Management**: All packages from registry with automatic selection  
✅ **Clean Host Configurations**: Only deployment-specific overrides  
✅ **Comprehensive Documentation**: Setup guide, architecture explanation, troubleshooting  
✅ **Infrastructure Registry Integration**: Deployment commands and access information  
✅ **Validated Configuration**: All builds tested before commit

This pattern should be followed for all new systemModule implementations to maintain architectural consistency and eliminate anti-patterns.