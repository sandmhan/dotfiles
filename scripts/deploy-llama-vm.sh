#!/usr/bin/env bash

# Llama.cpp VM Deployment Script
# Usage: ./deploy-llama-vm.sh <vm-ip> [vm-id]

set -euo pipefail

VM_IP="${1:-}"
VM_ID="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" >&2
}

usage() {
    cat << EOF
Usage: $0 <vm-ip> [vm-id]

Deploy llama.cpp configuration to a Proxmox VM.

Arguments:
    vm-ip   IP address of the target VM
    vm-id   Optional: Proxmox VM ID for configuration

Examples:
    $0 192.168.1.100
    $0 192.168.1.100 101

The script will:
1. Test connectivity to the VM
2. Deploy the NixOS configuration
3. Verify the llama-cpp service
4. Show status and access information
EOF
}

check_dependencies() {
    local missing_deps=()

    for cmd in nixos-rebuild ssh curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

test_connectivity() {
    local vm_ip="$1"

    log "Testing connectivity to $vm_ip..."

    if ! ping -c 1 -W 5 "$vm_ip" &> /dev/null; then
        error "Cannot reach VM at $vm_ip"
        exit 1
    fi

    if ! ssh -o ConnectTimeout=10 -o PasswordAuthentication=no "sandmhan@$vm_ip" "echo 'SSH connection successful'" 2>/dev/null; then
        error "Cannot SSH to sandmhan@$vm_ip"
        error "Ensure SSH key authentication is set up"
        exit 1
    fi

    log "Connectivity test passed"
}

deploy_configuration() {
    local vm_ip="$1"

    log "Deploying llama configuration to $vm_ip..."

    cd "$DOTFILES_DIR"

    # Test build first
    log "Testing build locally..."
    if ! nix build .#nixosConfigurations.llama.config.system.build.toplevel; then
        error "Build test failed"
        exit 1
    fi

    # Deploy to VM
    log "Deploying to VM..."
    if ! nixos-rebuild switch --target-host "sandmhan@$vm_ip" --flake .#llama --use-remote-sudo; then
        error "Deployment failed"
        exit 1
    fi

    log "Configuration deployed successfully"
}

verify_service() {
    local vm_ip="$1"

    log "Verifying llama-cpp service..."

    # Wait for service to start
    sleep 10

    # Check service status
    if ssh "sandmhan@$vm_ip" "systemctl is-active llama-cpp" &> /dev/null; then
        log "llama-cpp service is running"
    else
        warn "llama-cpp service is not running"
        ssh "sandmhan@$vm_ip" "systemctl status llama-cpp" || true
    fi

    # Test API endpoint
    log "Testing API endpoint..."
    if curl -s -f "http://$vm_ip:8080/health" &> /dev/null; then
        log "API endpoint is responding"
    else
        warn "API endpoint is not responding yet"
        warn "This is normal if no models are loaded"
    fi
}

show_status() {
    local vm_ip="$1"

    cat << EOF

${GREEN}=== Deployment Complete ===${NC}

VM IP: $vm_ip
API URL: http://$vm_ip:8080

${YELLOW}Next steps:${NC}
1. Upload models to /var/lib/llama-cpp/models/
2. Restart service: ssh sandmhan@$vm_ip 'sudo systemctl restart llama-cpp'
3. Test API: curl http://$vm_ip:8080/v1/models

${YELLOW}Useful commands:${NC}
- Check status: ssh sandmhan@$vm_ip 'systemctl status llama-cpp'
- View logs: ssh sandmhan@$vm_ip 'journalctl -u llama-cpp -f'
- Monitor GPU: ssh sandmhan@$vm_ip 'nvtop'

${YELLOW}Model management:${NC}
# Download a model (example)
ssh sandmhan@$vm_ip 'sudo -u llama-cpp wget -O /var/lib/llama-cpp/models/model.gguf https://example.com/model.gguf'

See hosts/llama/README.md for detailed documentation.
EOF
}

configure_proxmox_vm() {
    local vm_id="$1"

    if [[ -z "$vm_id" ]]; then
        warn "VM ID not provided, skipping Proxmox configuration"
        return 0
    fi

    log "Configuring Proxmox VM $vm_id for AI workloads..."

    cat << EOF

${YELLOW}Manual Proxmox configuration needed:${NC}

1. Set CPU and memory:
   qm set $vm_id --cores 4 --memory 8192

2. Configure GPU passthrough:
   qm set $vm_id --hostpci0 <pci-id>,pcie=1

   Find your GPU PCI ID with: lspci -nn | grep -i nvidia

3. Optional: Add dedicated storage for models:
   qm set $vm_id --scsi1 /path/to/storage,size=100G

Run these commands on your Proxmox host.
EOF
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    check_dependencies

    local vm_ip="$1"
    local vm_id="${2:-}"

    log "Starting llama.cpp VM deployment"
    log "Target: $vm_ip"

    test_connectivity "$vm_ip"
    deploy_configuration "$vm_ip"
    verify_service "$vm_ip"
    configure_proxmox_vm "$vm_id"
    show_status "$vm_ip"

    log "Deployment completed successfully"
}

main "$@"