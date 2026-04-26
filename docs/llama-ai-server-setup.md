# Local AI Server Setup Guide (llama.cpp)

## Overview

The Local AI Server provides self-hosted large language model (LLM) inference using llama.cpp. This enables private AI assistance, code completion, text generation, and chat capabilities without external API dependencies.

## Features

- **OpenAI-Compatible API**: Drop-in replacement for OpenAI API calls
- **Multiple Model Support**: Load and switch between different LLM models
- **Hardware Acceleration**: CPU, CUDA, OpenCL, and Metal support
- **Resource Management**: Configurable memory and CPU limits
- **Security**: Local processing, no data leaves your network
- **Integration Ready**: Compatible with existing AI tools and frameworks

## Architecture

```
┌─────────────────────┐    HTTP API    ┌─────────────────────┐    Model Files    ┌─────────────────┐
│   Client Apps       │◄──────────────►│   llama.cpp Server  │◄─────────────────►│   Model Storage │
│                     │                │                     │                   │                 │
│ • Open WebUI        │                │ • Model Loading     │                   │ • GGUF Models   │
│ • Code Editor       │                │ • Inference Engine  │                   │ • Multiple Sizes│
│ • Chat Applications │                │ • API Endpoints     │                   │ • Quantizations │
│ • Custom Scripts    │                │ • Memory Management │                   │ • Auto-Download │
└─────────────────────┘                └─────────────────────┘                   └─────────────────┘
                                                  │
                                                  │ Hardware Acceleration
                                                  ▼
                                        ┌─────────────────────┐
                                        │   GPU/Acceleration  │
                                        │                     │
                                        │ • NVIDIA CUDA       │
                                        │ • AMD OpenCL        │
                                        │ • Apple Metal       │
                                        │ • CPU Optimizations │
                                        └─────────────────────┘
```

## Configuration Options

### Basic Configuration

```nix
# In hosts/ai/default.nix
services.llama-cpp = {
  enable = true;
  host = "0.0.0.0";        # Allow external access
  port = 8080;             # API port
  
  models = {
    modelsPath = "/var/lib/llama-cpp/models";
    defaultModel = "llama-2-7b-chat.gguf";
  };
  
  acceleration = "cpu";     # or "cuda", "opencl", "metal"
  
  extraArgs = [
    "--ctx-size" "4096"     # Context window size
    "--threads" "8"         # CPU threads (adjust for your system)
    "--batch-size" "512"    # Batch processing size
    "--mlock"              # Lock model in memory
  ];
};
```

### Hardware Acceleration

#### CPU Optimization
```nix
services.llama-cpp = {
  acceleration = "cpu";
  extraArgs = [
    "--threads" "16"        # Use all CPU cores
    "--mlock"              # Lock model in RAM
    "--numa"               # NUMA-aware memory allocation
    "--cpu-mask" "0xFF"    # CPU core mask
  ];
};
```

#### NVIDIA GPU (CUDA)
```nix
services.llama-cpp = {
  acceleration = "cuda";
  extraArgs = [
    "--n-gpu-layers" "999"  # Offload all layers to GPU
    "--gpu-memory" "8192"   # GPU VRAM limit in MB
    "--split-mode" "layer"  # How to split across GPUs
  ];
  
  # Ensure CUDA environment
  environmentFile = "/var/lib/llama-cpp/cuda.env";
};

# Create environment file
systemd.tmpfiles.rules = [
  ''w /var/lib/llama-cpp/cuda.env - - - - CUDA_VISIBLE_DEVICES=0''
];
```

#### AMD GPU (OpenCL)
```nix
services.llama-cpp = {
  acceleration = "opencl";
  extraArgs = [
    "--opencl-gpu" "0"      # Select GPU device
    "--n-gpu-layers" "50"   # Partial GPU offload
  ];
};
```

### Model Management

#### Model Storage Structure
```
/var/lib/llama-cpp/models/
├── llama-2-7b-chat.gguf         # 7B parameter model (~4GB)
├── llama-2-13b-chat.gguf        # 13B parameter model (~7GB)  
├── codellama-7b-instruct.gguf   # Code-specialized model
├── mistral-7b-instruct.gguf     # Alternative 7B model
└── phi-3-mini-instruct.gguf     # Small model (~2GB)
```

#### Model Download Examples
```bash
# Download models manually
cd /var/lib/llama-cpp/models

# Llama 2 7B Chat (recommended starting point)
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf

# Code Llama 7B (for code assistance)
wget https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q4_K_M.gguf

# Mistral 7B (alternative high-quality model)
wget https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf

# Phi-3 Mini (lightweight model)
wget https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf
```

## Deployment

### Prerequisites

1. **Hardware Requirements**:
   - **Minimum**: 8GB RAM, 4 CPU cores
   - **Recommended**: 16GB+ RAM, 8+ CPU cores
   - **GPU (Optional)**: NVIDIA RTX series or AMD RX series

2. **Storage Requirements**:
   - **Models**: 4-50GB per model (depends on parameter count and quantization)
   - **System**: 10GB for dependencies and cache
   - **Total**: 50-100GB recommended

3. **Network Configuration**:
   - **API Access**: Port 8080 (configurable)
   - **Model Downloads**: Internet access for initial model downloads

### Deployment Steps

1. **Deploy AI Server Host**:
   ```bash
   # Using VM with GPU passthrough
   qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 102 --storage local-zfs
   qm set 102 --cores 6 --memory 14336 --name ai  # 14GB RAM for 7B models
   
   # GPU passthrough (if available)
   qm set 102 --hostpci0 01:00,pcie=1  # Pass through RTX 3060
   
   # Large storage for models
   qm set 102 --scsi1 local-zfs:100,size=100G
   
   qm start 102
   nixos-rebuild switch --target-host sandmhan@[AI_IP] --flake .#ai --sudo
   ```

2. **Download Initial Models**:
   ```bash
   # SSH to AI server and download models
   ssh ai-host
   
   # Download recommended starting model
   sudo -u llama-cpp wget -P /var/lib/llama-cpp/models \
     https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf
   
   # Set default model in configuration and redeploy
   ```

3. **Verify Installation**:
   ```bash
   # Check service status
   ssh ai-host "sudo systemctl status llama-cpp"
   
   # Test API endpoint
   curl http://[AI_IP]:8080/v1/models
   
   # Test completion
   curl -X POST http://[AI_IP]:8080/v1/completions \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama-2-7b-chat", 
       "prompt": "What is NixOS?",
       "max_tokens": 100
     }'
   ```

## API Usage

### OpenAI-Compatible Endpoints

The server provides OpenAI-compatible endpoints:

```bash
# List available models
curl http://ai-server:8080/v1/models

# Text completion
curl -X POST http://ai-server:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2-7b-chat",
    "prompt": "Explain quantum computing in simple terms:",
    "max_tokens": 150,
    "temperature": 0.7
  }'

# Chat completions (preferred for conversational models)
curl -X POST http://ai-server:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-2-7b-chat",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is NixOS and why would I use it?"}
    ],
    "max_tokens": 200,
    "temperature": 0.7
  }'
```

### Integration Examples

#### Python Client
```python
import openai

# Configure client to use local server
client = openai.OpenAI(
    base_url="http://ai-server:8080/v1",
    api_key="not-needed-for-local-server"
)

# Chat completion
response = client.chat.completions.create(
    model="llama-2-7b-chat",
    messages=[
        {"role": "system", "content": "You are a helpful homelab assistant."},
        {"role": "user", "content": "How do I configure a NixOS firewall?"}
    ],
    max_tokens=500
)

print(response.choices[0].message.content)
```

#### VS Code with Continue.dev
```json
// .continue/config.json
{
  "models": [
    {
      "title": "Homelab Llama",
      "provider": "openai",
      "model": "llama-2-7b-chat",
      "apiBase": "http://ai-server:8080/v1",
      "apiKey": "not-needed"
    }
  ]
}
```

#### Curl Scripts
```bash
#!/bin/bash
# homelab-ai-chat.sh
AI_SERVER="http://ai-server:8080"

ask_ai() {
    local prompt="$1"
    curl -s -X POST "$AI_SERVER/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"llama-2-7b-chat\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful homelab and NixOS expert.\"},
                {\"role\": \"user\", \"content\": \"$prompt\"}
            ],
            \"max_tokens\": 500,
            \"temperature\": 0.7
        }" | jq -r '.choices[0].message.content'
}

# Usage: ask_ai "How do I configure Nginx in NixOS?"
```

## Model Selection Guide

### Model Size vs Performance

| Model Size | RAM Required | GPU VRAM | Speed | Quality | Use Case |
|------------|--------------|----------|-------|---------|----------|
| **3B** | 4GB | 2GB | Fast | Good | Quick queries, code completion |
| **7B** | 8GB | 4GB | Medium | Better | General chat, documentation |
| **13B** | 16GB | 8GB | Slow | Best | Complex reasoning, analysis |
| **30B+** | 32GB+ | 16GB+ | Very Slow | Excellent | Research, specialized tasks |

### Recommended Models by Use Case

#### General Purpose
- **Llama 2 7B Chat**: Best all-around model
- **Mistral 7B Instruct**: High quality, efficient
- **Phi-3 Mini**: Lightweight, surprisingly capable

#### Code Assistance  
- **Code Llama 7B**: Specialized for programming
- **StarCoder**: Alternative coding model
- **DeepSeek Coder**: Strong coding capabilities

#### Specialized Tasks
- **Llama 2 13B**: Better reasoning for complex tasks
- **Vicuna 7B**: Strong conversational abilities
- **WizardLM**: Enhanced instruction following

### Quantization Levels

| Quantization | Size Reduction | Quality | Use Case |
|-------------|----------------|---------|----------|
| **Q2_K** | ~75% | Lower | Extreme resource constraints |
| **Q4_K_M** | ~50% | Good | **Recommended balance** |
| **Q5_K_M** | ~40% | Better | More VRAM available |
| **Q8_0** | ~25% | Best | Maximum quality |
| **F16** | 0% | Perfect | Research/benchmarking only |

## Performance Optimization

### Memory Optimization

```nix
services.llama-cpp = {
  extraArgs = [
    # Memory management
    "--mmap"               # Memory-map model files
    "--mlock"              # Lock model in RAM (prevents swapping)
    "--numa"               # NUMA-aware allocation
    
    # Cache optimization  
    "--ctx-size" "4096"    # Balance context vs memory
    "--batch-size" "512"   # Optimize for throughput
    
    # Threading
    "--threads" "8"        # Match physical CPU cores
    "--threads-batch" "8"  # Batch processing threads
  ];
  
  # Resource limits
  serviceConfig = {
    MemoryHigh = "12G";    # Soft memory limit
    MemoryMax = "14G";     # Hard memory limit
  };
};
```

### GPU Optimization

```nix
# For NVIDIA GPUs
services.llama-cpp = {
  acceleration = "cuda";
  extraArgs = [
    "--n-gpu-layers" "999"     # Offload all layers
    "--split-mode" "layer"     # Layer-wise splitting
    "--tensor-split" "1,0"     # Multi-GPU distribution
    "--main-gpu" "0"           # Primary GPU
  ];
};

# Monitor GPU usage
# nvidia-smi -l 1
```

### CPU Optimization

```nix
# Optimize for CPU inference
boot.kernelParams = [ 
  "intel_pstate=active"      # CPU frequency scaling
  "processor.max_cstate=1"   # Reduce CPU sleep states
];

# NUMA affinity for multi-socket systems
systemd.services.llama-cpp.serviceConfig = {
  CPUAffinity = "0-15";      # Bind to specific cores
  NUMAPolicy = "bind";       # NUMA binding
  NUMAMask = "0";           # NUMA node 0
};
```

## Monitoring & Management

### Performance Monitoring

```bash
# Monitor resource usage
ssh ai-host "htop"

# Check GPU utilization (if using CUDA)
ssh ai-host "nvidia-smi"

# Monitor API performance
curl http://ai-host:8080/health
curl http://ai-host:8080/metrics  # Prometheus metrics

# Check service logs
ssh ai-host "sudo journalctl -u llama-cpp -f"
```

### Model Management

```bash
# List loaded models
curl http://ai-host:8080/v1/models | jq

# Switch models (requires restart)
sudo systemctl stop llama-cpp
# Update configuration with new defaultModel
nixos-rebuild switch --flake .#ai
sudo systemctl start llama-cpp

# Check model loading time
journalctl -u llama-cpp | grep "loaded model"
```

### API Analytics

```python
#!/usr/bin/env python3
# ai-server-stats.py
import requests
import time
import json

def check_api_performance():
    start_time = time.time()
    
    response = requests.post("http://ai-host:8080/v1/completions", 
        json={
            "model": "llama-2-7b-chat",
            "prompt": "Hello",
            "max_tokens": 10
        })
    
    end_time = time.time()
    
    if response.status_code == 200:
        data = response.json()
        tokens = len(data['choices'][0]['text'].split())
        latency = end_time - start_time
        tokens_per_second = tokens / latency
        
        print(f"Latency: {latency:.2f}s")
        print(f"Tokens/sec: {tokens_per_second:.2f}")
    else:
        print(f"Error: {response.status_code}")

if __name__ == "__main__":
    check_api_performance()
```

## Integration with Homelab Services

### Home Assistant Integration

```yaml
# Home Assistant configuration.yaml
rest_command:
  ask_ai:
    url: "http://ai-server:8080/v1/chat/completions"
    method: post
    headers:
      Content-Type: "application/json"
    payload: |
      {
        "model": "llama-2-7b-chat",
        "messages": [
          {"role": "system", "content": "You are a smart home assistant. Be concise."},
          {"role": "user", "content": "{{ message }}"}
        ],
        "max_tokens": 100
      }

# Use in automations
automation:
  - alias: "AI Weather Summary"
    trigger:
      platform: time
      at: "07:00:00"
    action:
      service: rest_command.ask_ai
      data:
        message: "Summarize today's weather for planning outdoor activities"
```

### Matrix Bot Integration

```bash
# Simple Matrix bot using local AI
#!/bin/bash
# matrix-ai-bot.sh

MATRIX_SERVER="http://matrix.homelab.local"
AI_SERVER="http://ai-server:8080"
ROOM_ID="!room:homelab.local"

ask_ai() {
    local question="$1"
    curl -s -X POST "$AI_SERVER/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"llama-2-7b-chat\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"You are a helpful homelab assistant.\"},
                {\"role\": \"user\", \"content\": \"$question\"}
            ],
            \"max_tokens\": 300
        }" | jq -r '.choices[0].message.content'
}

send_to_matrix() {
    local message="$1"
    curl -X POST "$MATRIX_SERVER/_matrix/client/r0/rooms/$ROOM_ID/send/m.room.message" \
        -H "Authorization: Bearer $MATRIX_TOKEN" \
        -d "{\"msgtype\": \"m.text\", \"body\": \"$message\"}"
}

# Usage: echo "!ai How do I configure nginx?" | process_message
```

## Troubleshooting

### Common Issues

#### Out of Memory Errors
```bash
# Check memory usage
free -h
sudo systemctl status llama-cpp

# Solutions:
# 1. Use smaller model (7B instead of 13B)
# 2. Reduce context size: --ctx-size 2048
# 3. Add swap space
# 4. Increase VM memory allocation
```

#### GPU Not Detected
```bash
# Check GPU visibility
nvidia-smi
lspci | grep -i nvidia

# Verify CUDA installation
nvcc --version

# Check container access (if using)
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

#### Slow Inference Speed
```bash
# Check CPU utilization
htop

# Optimize configuration:
# --threads should match physical cores
# Use Q4_K_M quantization for speed
# Enable mlock and mmap
# Consider GPU acceleration
```

#### Model Loading Failures
```bash
# Check model file integrity
sha256sum /var/lib/llama-cpp/models/model.gguf

# Verify file permissions
ls -la /var/lib/llama-cpp/models/

# Check available disk space
df -h /var/lib/llama-cpp
```

### Debug Mode

```nix
# Enable verbose logging
services.llama-cpp.extraArgs = [
  "--verbose"
  "--log-format" "json"
];

# Check logs
journalctl -u llama-cpp -f
```

## Security Considerations

### Network Security

```nix
# Restrict API access to homelab networks only
networking.firewall = {
  allowedTCPPorts = [ 8080 ];
  extraCommands = ''
    # Only allow access from homelab VLANs
    iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 8080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8080 -j DROP
  '';
};
```

### Data Privacy

- **Local Processing**: All inference happens locally
- **No Telemetry**: No data sent to external services  
- **Model Privacy**: Models and conversations stay on your hardware
- **Audit Trail**: Full control over logging and data retention

### Resource Protection

```nix
# Prevent resource exhaustion
systemd.services.llama-cpp.serviceConfig = {
  # Memory limits
  MemoryMax = "12G";
  
  # CPU limits  
  CPUQuota = "800%";  # 8 cores max
  
  # Process limits
  TasksMax = 100;
  
  # File descriptor limits
  LimitNOFILE = 65536;
};
```

This local AI server setup provides powerful language model capabilities while maintaining complete privacy and control over your data and infrastructure.