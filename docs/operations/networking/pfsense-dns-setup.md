# pfSense DNS Override Setup Guide

Step-by-step guide for configuring local DNS overrides in pfSense so all homelab hosts are reachable by hostname instead of IP address.

## Prerequisites

- pfSense admin access (typically `https://10.0.0.1` or your gateway IP)
- pfSense DNS Resolver (Unbound) enabled (default on pfSense)

## Domain Convention

All hosts use the `homelab.local` domain suffix. Devices on the network can reach services at `<hostname>.homelab.local`.

---

## Step 1: Enable DNS Resolver

1. Navigate to **Services > DNS Resolver**
2. Ensure **Enable DNS Resolver** is checked
3. Under **Network Interfaces**, select the interfaces you want to serve DNS on (typically `All` or at minimum `LAN`; add VLAN interfaces when VLANs are implemented)
4. Ensure **DHCP Registration** is checked (registers DHCP leases as DNS entries)
5. Ensure **Static DHCP** is checked (registers static DHCP mappings as DNS entries)
6. Set **System Domain Local Zone Type** to `Transparent` (allows fallback to upstream for non-local queries)
7. Click **Save**, then **Apply Changes**

## Step 2: Set System Domain

1. Navigate to **System > General Setup**
2. Set **Domain** to `homelab.local`
3. Click **Save**

This ensures pfSense uses `homelab.local` as the default search domain for all DNS operations.

## Step 3: Add Host Overrides

Navigate to **Services > DNS Resolver**, scroll down to **Host Overrides**, and click **+ Add** for each entry below.

### Currently Deployed Hosts (Management VLAN - 10.0.0.0/24)

| Host | Domain | IP Address | Description |
|------|--------|------------|-------------|
| `proxmox` | `homelab.local` | `10.0.0.4` | Proxmox VE hypervisor (Dell node) |
| `agent-sandbox` | `homelab.local` | `10.0.0.5` | Autonomous agent sandbox VM |
| `matrix` | `homelab.local` | `10.0.0.6` | Matrix Synapse homeserver |
| `nixos-builder` | `homelab.local` | `10.0.0.7` | NixOS remote builder VM |
| `monitor` | `homelab.local` | `10.0.0.10` | Prometheus + Grafana (LXC) |
| `fitness` | `homelab.local` | `10.0.0.167` | wger fitness tracker |
| `vpn` | `homelab.local` | `10.0.0.168` | Tailscale subnet router |

### Planned Hosts (Not Yet Deployed)

> **Note:** VLANs are planned but not yet implemented. All services currently run on the flat `10.0.0.0/24` network. These hosts will receive IPs on `10.0.0.0/24` when deployed. Add DNS overrides once IPs are assigned.

| Host | Domain | IP Address | Description |
|------|--------|------------|-------------|
| `homeassistant` | `homelab.local` | `10.0.0.TBD` | Home Assistant |
| `nvr` | `homelab.local` | `10.0.0.TBD` | Frigate NVR |
| `llama` | `homelab.local` | `10.0.0.TBD` | LLM inference server |
| `git` | `homelab.local` | `10.0.0.TBD` | Forgejo Git server |
| `media` | `homelab.local` | `10.0.0.TBD` | Jellyfin + *arr media stack |
| `gaming` | `homelab.local` | `10.0.0.TBD` | Sunshine remote gaming |

### Planned LXC Containers (Not Yet Deployed)

| Host | Domain | IP Address | Description |
|------|--------|------------|-------------|
| `lxc-nas` | `homelab.local` | `10.0.0.TBD` | NAS (NFS/SMB) |
| `lxc-homeassistant` | `homelab.local` | `10.0.0.TBD` | Home Assistant (LXC) |
| `lxc-matrix` | `homelab.local` | `10.0.0.TBD` | Matrix (LXC) |
| `lxc-git` | `homelab.local` | `10.0.0.TBD` | Forgejo (LXC) |

For each entry:
1. Click **+ Add** under Host Overrides
2. Fill in **Host** (e.g., `proxmox`), **Domain** (`homelab.local`), **IP Address**, and **Description**
3. Click **Save**

After adding all entries, click **Apply Changes** at the top of the page.

## Step 4: Add Service Aliases (Optional)

For services where a friendly name is more intuitive than the hostname, add **Additional Names** (CNAME-like aliases) under the relevant host override. These point an alias to an existing host override entry.

Navigate to a host override entry, click the **edit** icon, and add aliases under **Additional Names for this Host**.

| Alias | Domain | Target Host Override | Purpose |
|-------|--------|---------------------|---------|
| `grafana` | `homelab.local` | `monitor` (10.0.0.10) | Grafana dashboard |
| `prometheus` | `homelab.local` | `monitor` (10.0.0.10) | Prometheus metrics UI |
| `synapse` | `homelab.local` | `matrix` (10.0.0.6) | Matrix Synapse alias |
| `wger` | `homelab.local` | `fitness` (10.0.0.167) | wger fitness alias |
| `jellyfin` | `homelab.local` | `media` (10.0.0.TBD) | Jellyfin media player |
| `sonarr` | `homelab.local` | `media` (10.0.0.TBD) | Sonarr TV manager |
| `radarr` | `homelab.local` | `media` (10.0.0.TBD) | Radarr movie manager |
| `prowlarr` | `homelab.local` | `media` (10.0.0.TBD) | Prowlarr indexer |
| `frigate` | `homelab.local` | `nvr` (10.0.0.TBD) | Frigate NVR alias |
| `ai` | `homelab.local` | `llama` (10.0.0.TBD) | AI API alias |
| `forgejo` | `homelab.local` | `git` (10.0.0.TBD) | Forgejo alias |
| `hass` | `homelab.local` | `homeassistant` (10.0.0.TBD) | Home Assistant short alias |
| `sunshine` | `homelab.local` | `gaming` (10.0.0.TBD) | Sunshine server alias |

For each alias:
1. Edit the parent host override entry
2. Under **Additional Names for this Host**, click **+ Add**
3. Fill in **Host** (the alias) and **Domain** (`homelab.local`)
4. Click **Save**, then **Apply Changes**

## Step 5: Configure DHCP to Push DNS

Ensure all DHCP clients receive pfSense as their DNS server so the overrides are used.

1. Navigate to **Services > DHCP Server**
2. For each interface (currently just `LAN`; add VLAN interfaces when implemented):
   - Under **Servers**, ensure the pfSense LAN IP (gateway) is listed as the DNS server
   - Under **Domain name**, enter `homelab.local`
3. Click **Save**

Repeat for each VLAN interface that should resolve homelab hostnames.

## Step 6: Verify DNS Resolution

From any machine on the network (after renewing DHCP lease or manually setting DNS):

```bash
# Test deployed hosts
nslookup proxmox.homelab.local
nslookup matrix.homelab.local
nslookup monitor.homelab.local
nslookup fitness.homelab.local

# Test aliases
nslookup grafana.homelab.local
nslookup prometheus.homelab.local

# Test planned hosts (should resolve even if VM isn't up yet)
nslookup llama.homelab.local
nslookup git.homelab.local
nslookup media.homelab.local

# Or use dig for more detail
dig +short agent-sandbox.homelab.local
dig +short homeassistant.homelab.local
```

If a lookup fails:
- Confirm the device is using pfSense as its DNS server: `cat /etc/resolv.conf`
- Renew DHCP: `sudo dhclient -r && sudo dhclient` (or `nmcli con down/up`)
- Check pfSense DNS Resolver logs: **Status > System Logs > DNS Resolver**

## Step 7: Update /etc/hosts on Gaia (Optional Fallback)

If you want hostname resolution to work even when pfSense is unreachable (e.g., during network maintenance), add a local fallback in your NixOS config for Gaia:

```nix
# hosts/gaia/default.nix (or an imported networking module)
networking.extraHosts = ''
  10.0.0.4    proxmox.homelab.local proxmox
  10.0.0.5    agent-sandbox.homelab.local agent-sandbox
  10.0.0.6    matrix.homelab.local matrix synapse
  10.0.0.7    nixos-builder.homelab.local nixos-builder
  10.0.0.10   monitor.homelab.local monitor grafana prometheus
  10.0.0.167  fitness.homelab.local fitness wger
  10.0.0.168  vpn.homelab.local vpn
'';
```

This is optional since pfSense DNS will handle it for all devices on the network.

---

## Summary

After completing these steps, all devices on your network can reach homelab services by name:

| What you type | Where it goes |
|---------------|---------------|
| `http://grafana.homelab.local:3000` | Grafana dashboard |
| `http://prometheus.homelab.local:9090` | Prometheus UI |
| `ssh agent@agent-sandbox.homelab.local` | Agent sandbox VM |
| `http://matrix.homelab.local` | Matrix homeserver |
| `http://fitness.homelab.local` | wger fitness tracker |
| `http://jellyfin.homelab.local:8096` | Jellyfin media (when deployed) |
| `http://git.homelab.local` | Forgejo Git server (when deployed) |
| `http://hass.homelab.local:8123` | Home Assistant (when deployed) |
| `http://ai.homelab.local:8080` | LLM inference API (when deployed) |
| `http://frigate.homelab.local:5000` | Frigate NVR (when deployed) |

### Maintenance

When adding new hosts to the homelab:
1. Add a host override in pfSense DNS Resolver
2. Add a DHCP static mapping if the host needs a fixed IP
3. Update the [Infrastructure Registry](../../architecture/infrastructure-registry.md)
