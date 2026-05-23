# Remote Desktop Modules

This document covers the Home Manager Moonlight/Sunshine feature modules. They are part of this repository's option-based Home Manager stack, not standalone modules intended for direct import into arbitrary Home Manager configs.

## Modules

### `moonlight.nix` - Client Module
- **Package**: `moonlight-qt`
- **Description**: Game streaming client for connecting to Sunshine or NVIDIA GameStream servers
- **Usage**: Enable with `myHome.features.enableMoonlight` on devices you want to stream TO (your home laptop)

### `sunshine.nix` - Server Module
- **Package**: `sunshine`
- **Description**: Game streaming server that hosts applications for remote access
- **Usage**: Enable with `myHome.features.enableSunshine` on devices you want to stream FROM (your work machine)
- **Features**:
  - Systemd user service (auto-starts with user session)
  - Web UI at https://localhost:47990
  - Basic configuration file with sensible defaults

## Usage Examples

### For the New Option-Based System

Enable in your profile (e.g., `home/profiles/desktop.nix` or `home/profiles/macos.nix`):

```nix
myHome.features = {
  enableMoonlight = true;  # For client
  enableSunshine = true;   # For server
};
```

**Platform Support**: Both modules work on Linux and macOS with automatic platform detection.

### Import Requirements

`home/modules/moonlight.nix` and `home/modules/sunshine.nix` read `config.myHome.*` options. They should be imported through a profile that also imports `home/options.nix` and sets the relevant `myHome.features` flags. The repository's standard profiles already provide that wiring; if you create a custom profile, import an existing profile such as `home/profiles/desktop.nix` or include the same option definitions before enabling these features.

## Setup Notes

### Sunshine Server Setup
1. After first launch, access web UI at https://localhost:47990
2. Default username: `admin`
3. Generate password: `echo -n "your_password" | openssl dgst -sha256`
4. Configure applications you want to stream in the web UI
5. Set up port forwarding if streaming over the internet:
   - TCP: 47989, 47990 (web UI)
   - UDP: 47998, 47999, 48000, 48002, 48010

### Moonlight Client Setup
1. Launch Moonlight
2. Add your Sunshine server by IP address
3. Enter the pairing PIN shown on the server
4. Select applications to stream

### Network Requirements
- **Local Network**: Usually works out of the box
- **Internet Streaming**: Requires port forwarding on server side
- **Performance**: Best with wired gigabit connection, decent with 5GHz WiFi

## Security Considerations
- Change default Sunshine password
- Use HTTPS for web UI access
- Consider VPN instead of direct internet exposure
- Sunshine supports hardware acceleration (NVENC/AMF) for better performance