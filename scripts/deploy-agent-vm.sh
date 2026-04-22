#!/usr/bin/env bash

# Agent VM Deployment Script
# Deploys the autonomous agent sandbox VM to Proxmox

set -euo pipefail

# Configuration
FLAKE_PATH="${FLAKE_PATH:-.}"
VM_ID="${AGENT_VM_ID:-900}"
VM_NAME="agent-sandbox"
PROXMOX_HOST="${PROXMOX_HOST:-proxmox.local}"
PROXMOX_USER="${PROXMOX_USER:-root}"
STORAGE="${PROXMOX_STORAGE:-local-zfs}"
BRIDGE="${PROXMOX_BRIDGE:-vmbr0}"

# Resource configuration for agent VM
CPU_CORES="${AGENT_CPU_CORES:-4}"
MEMORY_MB="${AGENT_MEMORY_MB:-8192}"
DISK_SIZE="${AGENT_DISK_SIZE:-40}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check dependencies
check_dependencies() {
    local deps=("nix" "ssh" "scp")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Required dependency '$dep' not found"
        fi
    done
}

# Build VMA image
build_vma_image() {
    log "Building Agent VM VMA image..."

    if ! nix build "${FLAKE_PATH}#nixosConfigurations.agentVMA.config.system.build.VMA" --out-link /tmp/agent-vm-image; then
        error "Failed to build VMA image"
    fi

    local vma_file
    vma_file=$(find /tmp/agent-vm-image -name "*.vma.zst" -type f | head -1)

    if [[ ! -f "$vma_file" ]]; then
        error "VMA file not found in build output"
    fi

    echo "$vma_file"
}

# Check if VM exists
vm_exists() {
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm status $VM_ID" &>/dev/null
}

# Create or update VM
deploy_vm() {
    local vma_file="$1"
    local vma_basename
    vma_basename=$(basename "$vma_file")
    local remote_path="/var/lib/vz/dump/$vma_basename"

    # Copy VMA file to Proxmox host
    log "Copying VMA file to Proxmox host..."
    if ! scp "$vma_file" "${PROXMOX_USER}@${PROXMOX_HOST}:$remote_path"; then
        error "Failed to copy VMA file to Proxmox host"
    fi

    # Check if VM already exists
    if vm_exists; then
        warn "VM $VM_ID already exists. Stopping and removing..."
        ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "
            qm stop $VM_ID --timeout 30 || true
            sleep 2
            qm destroy $VM_ID --purge || true
        "
    fi

    # Restore VM from VMA
    log "Restoring VM from VMA image..."
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "
        qmrestore '$remote_path' $VM_ID \
            --storage '$STORAGE' \
            --force
    "

    # Configure VM settings
    log "Configuring VM settings..."
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "
        qm set $VM_ID \
            --name '$VM_NAME' \
            --cores $CPU_CORES \
            --memory $MEMORY_MB \
            --net0 'virtio,bridge=$BRIDGE,firewall=1' \
            --onboot 0 \
            --protection 0 \
            --ostype l26 \
            --agent 1,fstrim_cloned_disks=1
    "

    # Resize disk if needed
    log "Resizing disk to ${DISK_SIZE}G..."
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "
        qm resize $VM_ID scsi0 ${DISK_SIZE}G
    "

    # Clean up remote VMA file
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "rm -f '$remote_path'"

    log "VM deployment complete!"
}

# Start VM
start_vm() {
    log "Starting Agent VM..."
    ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm start $VM_ID"

    info "Waiting for VM to boot..."
    local retries=0
    local max_retries=30

    while [[ $retries -lt $max_retries ]]; do
        if ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm agent $VM_ID ping" &>/dev/null; then
            log "VM is responding!"
            break
        fi

        ((retries++))
        echo -n "."
        sleep 5
    done

    if [[ $retries -ge $max_retries ]]; then
        warn "VM may not be fully ready yet. Check manually."
    fi
}

# Get VM IP address
get_vm_ip() {
    log "Getting VM IP address..."
    local ip
    ip=$(ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm agent $VM_ID network-get-interfaces" 2>/dev/null | \
         grep -A5 '"name": "enp1s0"' | \
         grep '"ip-address"' | \
         head -1 | \
         sed 's/.*"ip-address": "\([^"]*\)".*/\1/')

    if [[ -n "$ip" ]]; then
        info "Agent VM IP: $ip"
        echo "$ip" > /tmp/agent-vm-ip.txt
        return 0
    else
        warn "Could not determine VM IP address"
        return 1
    fi
}

# Test SSH connectivity
test_ssh() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        if [[ -f /tmp/agent-vm-ip.txt ]]; then
            ip=$(cat /tmp/agent-vm-ip.txt)
        else
            error "No IP address provided and none found"
        fi
    fi

    log "Testing SSH connectivity to $ip..."

    local retries=0
    local max_retries=20

    while [[ $retries -lt $max_retries ]]; do
        if ssh -o ConnectTimeout=5 -o BatchMode=yes "agent@$ip" "echo 'SSH connection successful'" &>/dev/null; then
            log "SSH connection successful!"
            return 0
        fi

        ((retries++))
        echo -n "."
        sleep 10
    done

    warn "SSH connection failed. You may need to configure SSH keys manually."
    return 1
}

# Deploy NixOS configuration
deploy_config() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        if [[ -f /tmp/agent-vm-ip.txt ]]; then
            ip=$(cat /tmp/agent-vm-ip.txt)
        else
            error "No IP address provided and none found"
        fi
    fi

    log "Deploying NixOS configuration to agent VM..."

    nixos-rebuild switch \
        --flake "${FLAKE_PATH}#agent-sandbox" \
        --target-host "agent@$ip" \
        --use-remote-sudo

    log "Configuration deployed successfully!"
}

# Setup SSH keys
setup_ssh() {
    local ip="${1:-}"
    if [[ -z "$ip" ]]; then
        if [[ -f /tmp/agent-vm-ip.txt ]]; then
            ip=$(cat /tmp/agent-vm-ip.txt)
        else
            error "No IP address provided and none found"
        fi
    fi

    log "Setting up SSH keys for agent VM..."

    # Generate SSH keys if they don't exist
    local key_file="$HOME/.ssh/agent_vm_ed25519"
    if [[ ! -f "$key_file" ]]; then
        ssh-keygen -t ed25519 -C "agent-vm-access" -f "$key_file" -N ""
        log "Generated SSH key: ${key_file}.pub"
    fi

    # Copy public key to VM
    ssh-copy-id -i "${key_file}.pub" "agent@$ip"

    log "SSH key setup complete!"
}

# Show VM status
show_status() {
    local status
    status=$(ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm status $VM_ID" 2>/dev/null || echo "not found")

    info "Agent VM Status: $status"

    if [[ "$status" == *"running"* ]]; then
        if get_vm_ip; then
            local ip
            ip=$(cat /tmp/agent-vm-ip.txt)
            info "Agent VM IP: $ip"
            info "SSH command: ssh agent@$ip"
            info "Claude Code setup: ssh agent@$ip 'curl -fsSL https://claude.ai/install | sh'"
        fi
    fi
}

# Show usage
show_usage() {
    cat << EOF
Agent VM Deployment Script

Usage: $0 [COMMAND]

Commands:
    deploy      Build VMA image and deploy to Proxmox
    start       Start the agent VM
    stop        Stop the agent VM
    status      Show VM status and connection info
    ssh         Connect to agent VM via SSH
    config      Deploy NixOS configuration to running VM
    setup-keys  Set up SSH keys for agent VM access
    destroy     Stop and remove the agent VM
    help        Show this help message

Environment Variables:
    AGENT_VM_ID         VM ID on Proxmox (default: 900)
    PROXMOX_HOST        Proxmox hostname (default: proxmox.local)
    PROXMOX_USER        Proxmox username (default: root)
    PROXMOX_STORAGE     Storage for VM (default: local-zfs)
    PROXMOX_BRIDGE      Network bridge (default: vmbr0)
    AGENT_CPU_CORES     CPU cores (default: 4)
    AGENT_MEMORY_MB     Memory in MB (default: 8192)
    AGENT_DISK_SIZE     Disk size in GB (default: 40)

Examples:
    $0 deploy           # Build and deploy agent VM
    $0 start            # Start the VM
    $0 config           # Deploy configuration updates
    $0 status           # Check VM status and get IP
EOF
}

# Main function
main() {
    local command="${1:-help}"

    case "$command" in
        deploy)
            check_dependencies
            local vma_file
            vma_file=$(build_vma_image)
            deploy_vm "$vma_file"
            start_vm
            get_vm_ip
            show_status
            ;;
        start)
            start_vm
            get_vm_ip
            show_status
            ;;
        stop)
            log "Stopping agent VM..."
            ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "qm stop $VM_ID"
            ;;
        status)
            show_status
            ;;
        ssh)
            if [[ -f /tmp/agent-vm-ip.txt ]]; then
                local ip
                ip=$(cat /tmp/agent-vm-ip.txt)
                exec ssh "agent@$ip"
            else
                get_vm_ip
                local ip
                ip=$(cat /tmp/agent-vm-ip.txt)
                exec ssh "agent@$ip"
            fi
            ;;
        config)
            local ip="${2:-}"
            deploy_config "$ip"
            ;;
        setup-keys)
            local ip="${2:-}"
            setup_ssh "$ip"
            ;;
        destroy)
            warn "This will permanently destroy the agent VM!"
            read -p "Are you sure? (yes/no): " -r
            if [[ $REPLY == "yes" ]]; then
                ssh "${PROXMOX_USER}@${PROXMOX_HOST}" "
                    qm stop $VM_ID --timeout 30 || true
                    qm destroy $VM_ID --purge
                "
                log "Agent VM destroyed"
            else
                info "Operation cancelled"
            fi
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $command. Use '$0 help' for usage information."
            ;;
    esac
}

# Run main function with all arguments
main "$@"