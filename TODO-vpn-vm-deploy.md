# TODO: Deploy Tailscale Subnet Router VM

Temporary reference for deploying the VPN/Tailscale VM on Proxmox.
Delete this file after the VM is deployed and configured.

## Steps

### 1. Build the VMA image

```bash
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
```

### 2. Transfer to Proxmox host

```bash
scp result/*.vma.zst root@<proxmox-ip>:/var/lib/vz/dump/
```

### 3. Restore as a new VM on Proxmox

Pick an unused VM ID (e.g. 110).

```bash
ssh root@<proxmox-ip>
qmrestore /var/lib/vz/dump/<file>.vma.zst <VMID> --storage local-zfs --force
qm set <VMID> --cores 1 --memory 1024
qm start <VMID>
```

### 4. Grab the host's age key

```bash
ssh sandmhan@<vm-ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
```

### 5. Update .sops.yaml

Replace the `&vpn_key age1...` placeholder with the real key from step 4.

### 6. Re-encrypt tailscale secrets for the new host

Add `*vpn_key` to the tailscale creation rule in `.sops.yaml`, then:

```bash
sops updatekeys secrets/tailscale/secrets.yaml
git add .sops.yaml secrets/tailscale/secrets.yaml
```

### 7. Deploy the Tailscale config to the VM

```bash
nixos-rebuild switch --target-host sandmhan@<vm-ip> --flake .#vpn --sudo
```

### 8. Verify

```bash
ssh sandmhan@<vm-ip> 'sudo tailscale status'
```

### 9. Approve subnet routes

In [Tailscale admin console](https://login.tailscale.com/admin/machines), find the vpn node and approve the advertised routes (10.0.0.0/24, 10.0.20.0/24).

### 10. Remove Gaia as subnet router (optional)

Once the VM is confirmed working, remove `advertiseRoutes` from `hosts/gaia/default.nix` so only the always-on VM handles subnet routing.

### 11. Clean up

Delete this file.
