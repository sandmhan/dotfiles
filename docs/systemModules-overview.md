# SystemModules Overview & Documentation Index

## Overview

The `systemModules/` directory contains reusable NixOS service configurations that can be imported by any host configuration. These modules provide declarative configuration for homelab services with consistent patterns for security, networking, and integration.

## Available Modules

| Module | Status | Description | Documentation |
|--------|--------|-------------|---------------|
| **wireguard.nix** | ✅ Complete | VPN server for secure remote access | [WireGuard Setup](./wireguard-client-configs.md) |
| **monitoring.nix** | ✅ Complete | Prometheus + Grafana observability stack | [Monitoring Setup](./monitoring-setup.md) |
| **frigate.nix** | ✅ Complete | Network Video Recorder with AI detection | [Frigate NVR Setup](./frigate-nvr-setup.md) |
| **llama.nix** | ✅ Complete | Local AI inference server (llama.cpp) | [AI Server Setup](./llama-ai-server-setup.md) |
| **matrix.nix** | ✅ Complete | Matrix homeserver (Synapse + Coturn) | [Matrix Setup](../SOPS-SETUP.md#matrix-configuration) |
| **sops.nix** | ✅ Complete | Encrypted secrets management | [SOPS Setup](./sops-secrets-setup.md) |
| **jellyfin.nix** | 🚧 Stub | Media server (basic configuration) | *Needs expansion* |

## Module Architecture

### Common Patterns

All systemModules follow these conventions:

```nix
# Standard module structure
{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.servicename;
in {
  # Options definition
  options.homelab.servicename = {
    enable = lib.mkEnableOption "Service description";
    # Service-specific options...
  };
  
  # Implementation
  config = lib.mkIf cfg.enable {
    # Service configuration
    # Firewall rules
    # User/group creation
    # Directory setup
    # Integration points
  };
}
```

### Integration Points

- **SOPS Secrets**: All modules integrate with encrypted secret management
- **Monitoring**: Prometheus metrics and health checks where applicable
- **Networking**: Consistent firewall and VLAN configuration
- **User Management**: Standardized service users and permissions
- **Logging**: Structured logging to journald

## Deployment Patterns

### Host Configuration Structure

```
hosts/
├── service-name/           # VM deployment
│   ├── default.nix        # Host-specific config
│   └── hardware-configuration.nix
├── lxc-service-name/      # Container deployment (optional)
│   └── default.nix        # Resource-optimized config
└── server/                # Base template for all VMs
    ├── default.nix
    ├── hardware-configuration.nix
    ├── networking.nix
    └── ssh.nix
```

### Standard Import Pattern

```nix
# In hosts/service/default.nix
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix              # Base VM config
    ../server/hardware-configuration.nix
    ../../systemModules/service.nix    # Service module
    ../../systemModules/sops.nix       # Secrets
  ];
  
  networking.hostName = systemSettings.hostname;
  
  # Enable service with custom options
  homelab.service = {
    enable = true;
    # service-specific configuration
  };
  
  # Additional host-specific configuration
}
```

## Service Categories

### Infrastructure Services

**Essential homelab foundation services that other services depend on.**

| Service | Module | Provides | Dependencies |
|---------|--------|----------|-------------|
| **SOPS** | `sops.nix` | Encrypted secret management | None |
| **Monitoring** | `monitoring.nix` | Prometheus + Grafana observability | None |
| **WireGuard** | `wireguard.nix` | Secure remote VPN access | SOPS |

### Communication Services

**Services for messaging, collaboration, and notifications.**

| Service | Module | Provides | Dependencies |
|---------|--------|----------|-------------|
| **Matrix** | `matrix.nix` | Self-hosted chat + agent control | SOPS, PostgreSQL |

### Media & Content Services

**Services for media streaming, content management, and entertainment.**

| Service | Module | Provides | Dependencies |
|---------|--------|----------|-------------|
| **Jellyfin** | `jellyfin.nix` | Media server and streaming | Storage |
| **Frigate** | `frigate.nix` | Network Video Recorder + AI | Storage, Monitoring |

### AI & Automation Services

**Services providing artificial intelligence and automation capabilities.**

| Service | Module | Provides | Dependencies |
|---------|--------|----------|-------------|
| **Llama.cpp** | `llama.nix` | Local AI inference server | GPU (optional) |

## Configuration Examples

### Basic Service Deployment

```nix
# hosts/monitor/default.nix
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../../systemModules/monitoring.nix
    ../../systemModules/sops.nix
  ];
  
  networking.hostName = "monitor";
  
  homelab.monitoring = {
    enable = true;
    prometheus.retention = "365d";
    grafana.domain = "grafana.homelab.local";
  };
}
```

### Multi-Service Host

```nix
# hosts/media/default.nix
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../../systemModules/jellyfin.nix
    ../../systemModules/monitoring.nix  # Self-monitoring
    ../../systemModules/sops.nix
  ];
  
  networking.hostName = "media";
  
  # Enable multiple services
  homelab.monitoring.nodeExporter.enable = true;  # Monitoring integration
  services.jellyfin.enable = true;                # Media server
  
  # Service integration
  networking.firewall.allowedTCPPorts = [ 8096 9100 ];
}
```

### LXC Container Optimization

```nix
# hosts/lxc-monitor/default.nix
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../lxc-base/default.nix           # Container-optimized base
    ../../systemModules/monitoring.nix
    ../../systemModules/sops.nix
  ];
  
  homelab.monitoring = {
    enable = true;
    prometheus.retention = "180d";    # Reduced for container
    loki.enable = false;             # Disabled to save resources
  };
}
```

## Service Dependencies

### Dependency Graph

```
                    ┌─────────────┐
                    │    SOPS     │
                    │  (secrets)  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌────▼────┐ ┌─────▼─────┐
        │Monitoring │ │WireGuard│ │  Matrix   │
        │(metrics)  │ │  (VPN)  │ │  (chat)   │
        └─────┬─────┘ └─────────┘ └───────────┘
              │
        ┌─────▼─────┐
        │  Frigate  │
        │   (NVR)   │
        └───────────┘
        
┌─────▼─────┐ ┌─────────┐ ┌─────────┐
│  Jellyfin │ │ Llama   │ │ Future  │
│  (media)  │ │ (AI)    │ │Services │
└───────────┘ └─────────┘ └─────────┘
```

### Deployment Order

**Phase 1 - Foundation**:
1. `sops.nix` - Essential for all other services
2. `monitoring.nix` - Observability for infrastructure
3. `wireguard.nix` - Remote access capability

**Phase 2 - Core Services**:
4. `matrix.nix` - Communication and agent control
5. `frigate.nix` - Security and surveillance  

**Phase 3 - Advanced Services**:
6. `llama.nix` - AI capabilities (requires GPU)
7. `jellyfin.nix` - Media services (requires storage)

## Module Development Guidelines

### Creating New Modules

```nix
# systemModules/newservice.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.newservice;
in {
  options.homelab.newservice = {
    enable = lib.mkEnableOption "NewService description";
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Service port";
    };
    
    domain = lib.mkOption {
      type = lib.types.str;
      default = "newservice.homelab.local";
      description = "Service domain";
    };
    
    # Add service-specific options...
  };
  
  config = lib.mkIf cfg.enable {
    # Service configuration
    services.newservice = {
      enable = true;
      port = cfg.port;
      # ...
    };
    
    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];
    
    # User management (if needed)
    users.users.newservice = {
      isSystemUser = true;
      group = "newservice";
      # ...
    };
    users.groups.newservice = {};
    
    # SOPS integration (if needed)
    sops.secrets."newservice/password" = {
      owner = "newservice";
      group = "newservice";
    };
    
    # Monitoring integration (if applicable)
    services.prometheus.exporters.newservice = {
      enable = true;
      port = cfg.port + 1;
    };
    
    # Health checks
    systemd.services.newservice-health-check = {
      # Health monitoring configuration
    };
  };
}
```

### Module Standards

1. **Namespace**: All homelab services under `homelab.*` options
2. **Secrets**: Integrate with SOPS for all sensitive configuration
3. **Monitoring**: Provide Prometheus metrics where applicable
4. **Firewall**: Always configure necessary ports
5. **Documentation**: Include comprehensive setup guides
6. **Examples**: Provide working configuration examples

### Testing Modules

```bash
# Test module builds correctly
nixos-rebuild dry-build --flake .#host-with-service

# Validate options
nix-instantiate --eval --expr '(import <nixpkgs/nixos> {
  configuration = ./hosts/service/default.nix;
}).options.homelab.service'

# Check for undefined references
nix-instantiate --parse ./systemModules/service.nix
```

## Integration Patterns

### Service Discovery

Services can discover each other through consistent naming:

```nix
# In any service configuration
homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "matrix-synapse";
    static_configs = [{
      targets = [ "matrix.homelab.local:8008" ];
    }];
  }
];
```

### Cross-Service Communication

```nix
# Matrix to AI integration example
systemModules.matrix.settings = {
  app_service_config_files = [
    # AI bot service registration
    config.sops.templates."matrix-ai-bridge".path
  ];
};

# Template combining multiple secrets
sops.templates."matrix-ai-bridge" = {
  content = ''
    id: ai-assistant
    url: http://llama.homelab.local:8080
    as_token: ${config.sops.placeholder."matrix/ai-bot-token"}
    hs_token: ${config.sops.placeholder."matrix/homeserver-token"}
  '';
};
```

### Resource Sharing

```nix
# Shared storage configuration
homelab.storage = {
  nfsExports = {
    "/srv/media" = [ "jellyfin.homelab.local" "frigate.homelab.local" ];
    "/srv/backups" = [ "*.homelab.local" ];
  };
};
```

## Migration & Maintenance

### Module Updates

```bash
# Update single service
nixos-rebuild switch --target-host user@service-host --flake .#service

# Update all services in parallel
for host in monitor matrix vpn; do
  nixos-rebuild switch --target-host user@$host --flake .#$host --sudo &
done
wait

# Rollback if needed
nixos-rebuild --rollback --target-host user@service-host --sudo
```

### Service Health Monitoring

All modules include health check integration with monitoring stack:

```bash
# Check service health via monitoring
curl http://monitor.homelab.local:9090/api/v1/query?query=up{job="homelab-services"}

# Direct service health checks
curl http://service.homelab.local:port/health
```

## Future Module Development

### Planned Modules

- **NAS** (`nas.nix`): NFS/Samba file server with backup automation
- **Git Server** (`forgejo.nix`): Self-hosted Git with CI/CD
- **Home Assistant** (`homeassistant.nix`): IoT automation platform  
- **Media Stack** (`nixflix.nix`): Complete *arr stack with qBittorrent
- **Fitness Tracking** (`wger.nix`): Exercise and nutrition tracking

### Module Requests

To request new modules or enhancements:

1. **Define Use Case**: Clear description of service purpose
2. **Identify Dependencies**: Required services and resources
3. **Security Requirements**: Secret management needs  
4. **Integration Points**: How it connects to existing services
5. **Resource Requirements**: CPU, memory, storage, GPU needs

This modular architecture enables flexible, scalable homelab deployments while maintaining consistency and best practices across all services.