---
name: container-management
description: "Use for OCI container strategy, lifecycle management, and health checks"
---

# Container Management for Homelab Services

## Purpose
Manage OCI containers for services without native NixOS packages.

## Container Strategy
- Use containers only when native NixOS services are unavailable
- Prefer official images from trusted sources
- Implement proper networking and security isolation
- Ensure persistent storage for stateful services
- Include health checks and monitoring

## Configuration Patterns

### OCI Container Service
```nix
virtualisation.oci-containers.containers.myservice = {
  image = "myservice:latest";
  ports = [ "8080:8080" ];
  volumes = [ "/var/lib/myservice:/data" ];
  environment = {
    CONFIG_FILE = "/data/config.yaml";
  };
  extraOptions = [
    "--health-cmd=curl -f http://localhost:8080/health"
    "--health-interval=30s"
    "--health-retries=3"
  ];
};
```

### Service Integration
- Configure systemd dependencies
- Set up reverse proxy with nginx
- Implement backup strategies for container data
- Monitor resource usage and logs

## Management Tasks
- Container lifecycle management
- Image updates and security patching
- Data backup and recovery
- Performance monitoring and optimization
