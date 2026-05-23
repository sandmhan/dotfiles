# WireGuard Client Configuration Guide

## Overview

This guide provides client configuration templates for connecting to your homelab WireGuard VPN server.

## Prerequisites

1. **WireGuard VPN server deployed** (using `hosts/vpn/default.nix`)
2. **Secrets populated** in `secrets/wireguard/secrets.yaml`
3. **Server public key** obtained from deployed server
4. **Client keypairs generated** for each device

## Key Generation

### Server Keys (one-time setup)
```bash
# Generate server private key (store in sops secrets)
SERVER_PRIVATE_KEY=$(wg genkey)
echo $SERVER_PRIVATE_KEY  # Add to secrets/wireguard/secrets.yaml

# Generate server public key (add to hosts/vpn/default.nix)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)
echo $SERVER_PUBLIC_KEY  # Update publicKey in host config
```

### Client Keys (per device)
```bash
# Generate client private key (keep secure on device)
CLIENT_PRIVATE_KEY=$(wg genkey)

# Generate client public key (add to server's peer list)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)

# Optional: Generate preshared key for additional security
PRESHARED_KEY=$(wg genpsk)
```

## Client Configurations

### Framework Laptop (Linux)

**File**: `/etc/wireguard/homelab.conf`
```ini
[Interface]
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
Address = 10.100.0.2/32
DNS = 10.0.0.1  # Your homelab DNS server

# Optional: Only route homelab traffic through VPN
# Table = off
# PostUp = ip route add 10.0.0.0/16 dev wg0
# PostDown = ip route del 10.0.0.0/16 dev wg0

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
PresharedKey = YOUR_PRESHARED_KEY_HERE  # Optional, for added security
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 10.0.0.0/16, 10.100.0.0/24  # Homelab subnets + VPN subnet

# Keep connection alive through NAT
PersistentKeepalive = 25
```

**Usage**:
```bash
# Start connection
sudo wg-quick up homelab

# Check status
sudo wg show

# Stop connection
sudo wg-quick down homelab

# Enable on boot
sudo systemctl enable wg-quick@homelab
```

### Android Phone

**QR Code Generation** (run on server):
```bash
# Create temporary client config
cat > /tmp/android-config.conf << EOF
[Interface]
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
Address = 10.100.0.3/32
DNS = 10.0.0.1

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
PresharedKey = YOUR_PRESHARED_KEY_HERE
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 10.0.0.0/16, 10.100.0.0/24
PersistentKeepalive = 25
EOF

# Generate QR code for WireGuard app
qrencode -t ansiutf8 < /tmp/android-config.conf
```

**Setup**:
1. Install [WireGuard app](https://play.google.com/store/apps/details?id=com.wireguard.android)
2. Tap "+" → "Scan from QR code"
3. Scan the generated QR code
4. Name the tunnel "Homelab"
5. Toggle to connect

### iOS/iPad

**Configuration** (similar to Android):
```ini
[Interface]
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
Address = 10.100.0.4/32
DNS = 10.0.0.1

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
PresharedKey = YOUR_PRESHARED_KEY_HERE
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 10.0.0.0/16, 10.100.0.0/24
PersistentKeepalive = 25
```

**Setup**:
1. Install [WireGuard app](https://apps.apple.com/app/wireguard/id1441195209)
2. Use QR code method (same as Android)
3. Or manually enter configuration

### macOS Laptop

**File**: `/usr/local/etc/wireguard/homelab.conf`
```ini
[Interface]
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
Address = 10.100.0.5/32
DNS = 10.0.0.1

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
PresharedKey = YOUR_PRESHARED_KEY_HERE
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 10.0.0.0/16, 10.100.0.0/24
PersistentKeepalive = 25
```

**Usage** (via Homebrew WireGuard):
```bash
# Install WireGuard
brew install wireguard-tools

# Start tunnel
sudo wg-quick up homelab

# GUI app alternative
brew install --cask wireguard
```

## Split Tunneling vs Full Tunnel

### Split Tunneling (Recommended)
**Pros**: Only homelab traffic goes through VPN, normal internet stays direct
**Config**: `AllowedIPs = 10.0.0.0/16, 10.100.0.0/24`

### Full Tunneling
**Pros**: All traffic encrypted and routed through homelab
**Config**: `AllowedIPs = 0.0.0.0/0`
**Note**: Requires homelab to have internet access and NAT configured

## Firewall & Port Forwarding

### Router Configuration
Forward UDP port 51820 to WireGuard server IP:
```
External Port: 51820 (UDP)
Internal IP: [WireGuard VM IP]
Internal Port: 51820 (UDP)
```

### DNS Configuration
Consider setting up a dynamic DNS service for consistent access:
```
Endpoint = homelab.your-domain.com:51820
```

## Troubleshooting

### Connection Issues
```bash
# Check server status
sudo wg show

# Check firewall
sudo iptables -L -n | grep 51820

# Check routing
ip route show table all
```

### Access Issues
```bash
# Test connectivity to homelab services
ping 10.0.0.1
curl http://10.0.0.6:80  # Matrix server

# Check NAT/forwarding
sudo iptables -L FORWARD -n -v
```

### Performance Issues
```bash
# Check WireGuard statistics
sudo wg show wg0 dump

# Test bandwidth
iperf3 -s  # On homelab server
iperf3 -c 10.0.0.X  # From client
```

## Security Best Practices

1. **Rotate keys periodically** (every 6-12 months)
2. **Use preshared keys** for post-quantum security
3. **Limit AllowedIPs** to minimum required subnets
4. **Monitor connections** via Prometheus metrics
5. **Revoke compromised clients** immediately
6. **Use strong passwords** on client devices
7. **Enable device lock screens** on mobile clients

## Integration with Homelab Services

Once connected via WireGuard, access homelab services directly:

- **Matrix**: `https://matrix.sandmhan.dev` (if DNS configured)
- **Grafana**: `http://10.0.0.10:3000` (monitoring LXC)
- **Home Assistant**: `http://[HA_IP]:8123` (not yet deployed)
- **SSH to VMs**: `ssh user@10.0.0.X`
- **Proxmox Web UI**: `https://10.0.0.4:8006`

## Client Management

### Adding New Clients
1. Generate new client keypair
2. Add public key to `secrets/wireguard/secrets.yaml`
3. Re-deploy WireGuard server: `nixos-rebuild switch`
4. Provide client with their private key and server config

### Revoking Clients
1. Remove client from `secrets/wireguard/secrets.yaml`
2. Re-deploy WireGuard server
3. Client will be immediately disconnected

### Monitoring Clients
Access Prometheus metrics at `http://[wireguard-server]:9586/metrics` for:
- Connected clients
- Data transfer statistics  
- Connection duration
- Peer handshake status