# SystemModules Architecture Guide

## Overview

This guide documents the standardized architecture patterns for systemModules implementation, established after the anti-pattern refactoring. These patterns ensure maintainable, scalable, and well-documented homelab infrastructure.

## Core Architecture Principles

### 1. Centralized Package Management

All packages are defined in `systemModules/packages.nix` with automatic selection based on service type and deployment environment.

```nix
# systemModules/packages.nix structure
{
  # Base packages for all homelab systems
  base = [ htop curl jq ncdu ripgrep ... ];
  
  # Service-specific package sets
  monitoring = [ prometheus grafana ];
  monitoringUtils = [ nethogs iftop ];  # VM-specific extras
  wireguard = [ wireguard-tools qrencode ];
  wireguardUtils = [ jq ];  # Host-specific extras
  
  # Utility functions
  getServicePackages = service: base ++ servicePackages;
  getCombinedPackages = services: base ++ flattenedServicePackages;
}
```

### 2. Intelligent Module Configuration

SystemModules use deployment types and resource profiles for automatic optimization:

```nix
options.homelab.servicename = {
  enable = mkEnableOption "Service description";
  
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
};
```

### 3. Smart Defaults Based on Environment

Configuration automatically adapts based on deployment context:

```nix
# Example: Automatic retention adjustment
retention = mkOption {
  type = types.str;
  default = 
    if cfg.deploymentType == "container" then "180d"
    else if cfg.resourceProfile == "minimal" then "90d"
    else "365d";
  description = "Data retention period";
};

# Example: Conditional feature enablement
loki.enable = mkOption {
  type = types.bool;
  default = cfg.deploymentType == "vm" && cfg.resourceProfile != "minimal";
  description = "Enable log aggregation";
};
```

## Implementation Pattern

### Standard SystemModule Structure

```nix
# systemModules/servicename.nix
{ config, lib, pkgs, ... }:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.servicename;
in {
  options.homelab.servicename = {
    enable = mkEnableOption "Service description";
    
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
      description = "Service port";
    };
    
    # More service options...
  };
  
  config = mkMerge [
    # Base service configuration
    (mkIf cfg.enable {
      # Core service setup
      services.servicename = {
        enable = true;
        port = cfg.port;
        # Base configuration...
      };
      
      # Firewall
      networking.firewall.allowedTCPPorts = [ cfg.port ];
      
      # Packages from centralized registry
      environment.systemPackages = servicePackages.servicename ++
        (optionals (cfg.deploymentType == "vm") servicePackages.servicenameUtils) ++
        servicePackages.base;
      
      # SOPS integration (if needed)
      sops.secrets."servicename/secret" = {
        owner = "servicename";
        group = "servicename";
      };
    })
    
    # VM-specific configuration
    (mkIf (cfg.enable && cfg.deploymentType == "vm") {
      # VM-specific settings
      boot.kernel.sysctl = {
        # VM optimizations
      };
    })
    
    # Container-specific configuration  
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      # Container optimizations
      boot.isContainer = true;
    })
  ];
}
```

### Host Configuration Pattern

Host configurations only override deployment-specific variations:

```nix
# hosts/servicename/default.nix
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/servicename.nix
    ../../systemModules/sops.nix
  ];
  
  networking.hostName = systemSettings.hostname;
  
  # Enable service with deployment-specific settings
  homelab.servicename = {
    enable = true;
    deploymentType = "vm";  # or "container"
    resourceProfile = "standard";  # or "minimal"/"high"
    
    # Override only deployment-specific variations
    domain = "servicename.homelab.local";
    
    # Extend defaults only where needed
    additionalConfig = {
      # Host-specific overrides
    };
  };
  
  # Additional host-specific configuration (minimal)
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
```

### Container Configuration Pattern

```nix
# hosts/lxc-servicename/default.nix  
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../lxc-base/default.nix
    ../../systemModules/servicename.nix
    ../../systemModules/sops.nix
  ];
  
  networking.hostName = systemSettings.hostname;
  
  # Container-optimized deployment
  homelab.servicename = {
    enable = true;
    deploymentType = "container";
    resourceProfile = "minimal";
    
    # Container-specific overrides only
    domain = "servicename.homelab.local";
    
    # Resource-conscious settings automatically applied
  };
  
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
```

## Package Management Patterns

### Adding New Service Packages

```nix
# systemModules/packages.nix - Add new service
rec {
  # ... existing packages ...
  
  # New service packages
  newservice = with pkgs; [
    newservice-binary
    newservice-cli
  ];
  
  # New service utilities (for VM deployments)
  newserviceUtils = with pkgs; [
    newservice-admin-tools
    debugging-utilities
  ];
  
  # Update final export
} // {
  inherit base monitoring ... newservice newserviceUtils;
  # ... rest of exports
}
```

### Using Packages in Modules

```nix
# In systemModule
environment.systemPackages = servicePackages.newservice ++
  (optionals (cfg.deploymentType == "vm") servicePackages.newserviceUtils) ++
  servicePackages.base;
```

## Deployment Type Behaviors

### VM Deployment (`deploymentType = "vm"`)
- **Resources**: Full resource allocation
- **Features**: All features enabled by default
- **Packages**: Includes service + utilities + base packages
- **Optimizations**: Performance-focused settings
- **Storage**: Higher retention periods
- **Logging**: Full logging and monitoring integration

### Container Deployment (`deploymentType = "container"`)
- **Resources**: Resource-conscious configuration
- **Features**: Non-essential features disabled
- **Packages**: Service + base packages only
- **Optimizations**: Memory and CPU efficiency
- **Storage**: Reduced retention periods  
- **Logging**: Essential logging only

### Hybrid Deployment (`deploymentType = "hybrid"`)
- **Use Case**: Service spanning multiple deployment types
- **Behavior**: Balanced configuration suitable for mixed environments
- **Features**: Core features enabled, optional features configurable

## Resource Profile Behaviors

### Minimal Profile (`resourceProfile = "minimal"`)
- **Target**: Resource-constrained environments (containers, low-spec VMs)
- **Features**: Only essential features enabled
- **Storage**: Minimum retention periods
- **Monitoring**: Basic metrics only

### Standard Profile (`resourceProfile = "standard"`)
- **Target**: Normal homelab deployments
- **Features**: Standard feature set enabled
- **Storage**: Reasonable retention periods
- **Monitoring**: Full monitoring integration

### High Profile (`resourceProfile = "high"`)
- **Target**: High-resource environments, critical services
- **Features**: All features enabled with enhanced settings
- **Storage**: Extended retention periods
- **Monitoring**: Enhanced monitoring with alerting

## Integration Patterns

### Service-to-Service Integration

Services automatically discover and integrate with each other through consistent naming:

```nix
# Monitoring integration example
services.prometheus.scrapeConfigs = [
  {
    job_name = "matrix-synapse";
    static_configs = [{
      targets = [ "matrix.homelab.local:8008" ];
    }];
    metrics_path = "/_synapse/metrics";
  }
];
```

### Cross-Service Communication

```nix
# Service configuration templates
sops.templates."service-integration" = {
  content = ''
    [external_service]
    endpoint = https://otherservice.homelab.local
    api_key = ${config.sops.placeholder."shared/api-key"}
  '';
  owner = "service-user";
};
```

## Documentation Requirements

Every systemModule **MUST** include:

### 1. Module Header Comment
```nix
# Service Name Module
# Brief description of service purpose and capabilities
{ config, lib, pkgs, ... }:
```

### 2. Comprehensive Setup Guide
- Purpose and architecture overview
- Configuration examples with explanations
- Deployment procedures for VM and container
- Integration patterns with other services
- Troubleshooting guide with common issues

### 3. Infrastructure Registry Update
Every service deployment must update `docs/infrastructure-registry.md` with:
- Host information and IP addresses
- Build commands for deployment
- Access methods and credentials
- Network configuration details
- Health check endpoints

## Testing and Validation

### Configuration Testing
```bash
# Test module builds correctly
nix build --dry-run .#nixosConfigurations.servicename.config.system.build.toplevel

# Test container variant
nix build --dry-run .#nixosConfigurations.lxc-servicename.config.system.build.toplevel

# Validate options
nix-instantiate --eval --expr '
  (import <nixpkgs/nixos> { 
    configuration = ./hosts/servicename/default.nix; 
  }).options.homelab.servicename'
```

### Deployment Validation
```bash
# Deploy to VM
nixos-rebuild switch --target-host user@host-ip --flake .#servicename --sudo

# Verify service health
curl http://host-ip:port/health

# Check monitoring integration
curl http://monitor.homelab.local:9090/api/v1/query?query=up{job="servicename"}
```

## Migration Pattern

### Converting Existing Modules

1. **Add Deployment Options**
```nix
# Add to existing module options
deploymentType = mkOption { /* standard options */ };
resourceProfile = mkOption { /* standard options */ };
```

2. **Move Packages to Registry**
```nix
# Remove from module config
environment.systemPackages = with pkgs; [ service-package ];

# Add to systemModules/packages.nix
servicename = with pkgs; [ service-package ];

# Update module to use registry
environment.systemPackages = servicePackages.servicename ++ servicePackages.base;
```

3. **Add Intelligent Defaults**
```nix
# Convert static defaults to conditional
option = mkOption {
  default = if cfg.deploymentType == "container" then "minimal-value" else "standard-value";
};
```

4. **Update Host Configurations**
```nix
# Remove duplicated settings from host configs
# homelab.servicename.port = 8080;  # Remove if matches module default

# Add deployment type
homelab.servicename = {
  enable = true;
  deploymentType = "vm";  # Add this
  # Keep only host-specific overrides
};
```

This architecture ensures:
- ✅ **Zero Configuration Duplication**: Modules provide intelligent defaults
- ✅ **Automatic Environment Optimization**: Based on deployment type and resource profile  
- ✅ **Consistent Package Management**: Centralized definitions with automatic selection
- ✅ **Maintainable Host Configurations**: Minimal overrides only
- ✅ **Comprehensive Documentation**: Required for every module
- ✅ **Validated Deployments**: All configurations tested before commit

Follow this pattern for all future systemModule development to maintain architectural consistency and eliminate anti-patterns.