# Llama.cpp VM Configuration

This configuration sets up a Proxmox VM optimized for running llama.cpp with GPU acceleration for AI inference workloads.

## VM Specifications

- **CPU**: 4 cores
- **RAM**: 8GB
- **GPU**: Dedicated GPU passthrough (NVIDIA/AMD)
- **Storage**: Boot disk + optional dedicated model storage
- **Network**: Exposed API on port 8080

## GPU Passthrough Setup

### Prerequisites

1. **Enable IOMMU in BIOS/UEFI**
2. **Configure GPU passthrough in Proxmox**:
   ```bash
   # Add to /etc/default/grub
   GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"  # or amd_iommu=on
   
   # Update GRUB
   update-grub
   
   # Add VFIO modules to /etc/modules
   vfio
   vfio_iommu_type1
   vfio_pci
   vfio_virqfd
   ```

3. **Find GPU PCI ID**:
   ```bash
   lspci -nn | grep -i nvidia  # or amd
   # Note the vendor:device ID (e.g., 10de:2204)
   ```

4. **Update hardware-configuration.nix**:
   - Replace `vfio-pci.ids=10de:2204` with your GPU's ID
   - Update UUID in filesystems if using dedicated storage

## Deployment

### 1. Build and Deploy VM

```bash
# Build configuration (test first)
nix build .#nixosConfigurations.llama.config.system.build.toplevel

# Deploy to VM
nixos-rebuild switch --target-host sandmhan@<llama-vm-ip> --flake .#llama --sudo
```

### 2. Configure VM in Proxmox

```bash
# Create VM with proper settings
qm create <VMID> --name llama-ai --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0

# Add GPU passthrough
qm set <VMID> --hostpci0 <pci-id>,pcie=1

# Set boot order and other settings
qm set <VMID> --boot order=scsi0 --scsi0 local:vm-<VMID>-disk-0
```

### 3. Model Management

```bash
# SSH into the VM
ssh sandmhan@<llama-vm-ip>

# Download models to /var/lib/llama-cpp/models/
# Example: Download a model
wget -O /var/lib/llama-cpp/models/llama-2-7b-chat.gguf \
  https://huggingface.co/example/model.gguf

# Set ownership
chown -R llama-cpp:llama-cpp /var/lib/llama-cpp/models/
```

## API Usage

The llama.cpp server exposes a REST API on port 8080:

### Health Check
```bash
curl http://<llama-vm-ip>:8080/health
```

### List Models
```bash
curl http://<llama-vm-ip>:8080/v1/models
```

### Generate Text
```bash
curl http://<llama-vm-ip>:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2-7b-chat.gguf",
    "prompt": "Hello, world!",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

### Chat Completion (OpenAI Compatible)
```bash
curl http://<llama-vm-ip>:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2-7b-chat.gguf",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "max_tokens": 100
  }'
```

## Service Management

```bash
# Check service status
systemctl status llama-cpp

# View logs
journalctl -u llama-cpp -f

# Restart service
systemctl restart llama-cpp

# Monitor GPU usage
nvtop
```

## Configuration Options

Edit `/hosts/llama/default.nix` to customize:

- **models.defaultModel**: Set a default model to load on startup
- **extraArgs**: Add custom llama.cpp arguments (context size, threads, etc.)
- **acceleration**: Change GPU backend (cuda/opencl/cpu)

Example configuration:
```nix
services.llama-cpp = {
  enable = true;
  host = "0.0.0.0";
  port = 8080;
  acceleration = "cuda";
  models.defaultModel = "llama-2-7b-chat.gguf";
  extraArgs = [
    "--ctx-size" "4096"
    "--threads" "4"
    "--n-gpu-layers" "32"
  ];
};
```

## Troubleshooting

### GPU Not Detected
1. Verify IOMMU is enabled: `dmesg | grep -i iommu`
2. Check VFIO binding: `lspci -k -s <pci-id>`
3. Verify GPU passthrough in VM: `lspci` inside VM

### Service Fails to Start
1. Check logs: `journalctl -u llama-cpp`
2. Verify model files exist and are readable
3. Check GPU drivers: `nvidia-smi` or `clinfo`

### API Not Accessible
1. Check firewall: `iptables -L`
2. Verify service is listening: `netstat -tlnp | grep 8080`
3. Test locally first: `curl localhost:8080/health`

## Performance Tuning

### Memory Optimization
- Increase `MemoryMax` in systemd service for larger models
- Use `mlock` to prevent swapping: add `--mlock` to extraArgs

### GPU Optimization
- Adjust `--n-gpu-layers` based on GPU memory
- Use `--tensor-split` for multi-GPU setups
- Monitor with `nvtop` or `nvidia-smi`

### Model Quantization
- Use GGUF models with appropriate quantization (Q4_K_M, Q5_K_M, Q8_0)
- Balance model size vs. quality based on available GPU memory