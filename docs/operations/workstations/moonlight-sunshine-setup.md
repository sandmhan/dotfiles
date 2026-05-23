# Moonlight/Sunshine Setup Guide

A complete guide for setting up remote desktop streaming between your work machine (Sunshine server) and home laptop (Moonlight client).

## 🖥️ Server Setup (Work Machine - Sunshine)

### 1. Initial Configuration
After installing the Sunshine module, start the service:

**Linux:**
```bash
# The systemd service should auto-start, but you can manually start it:
systemctl --user start sunshine

# Check if it's running:
systemctl --user status sunshine
```

**macOS:**
```bash
# The launchd service should auto-start, but you can manually manage it:
launchctl load ~/Library/LaunchAgents/org.homebrewformulas.sunshine.plist

# Check if it's running:
launchctl list | grep sunshine
```

### 2. Web UI Setup
1. Open browser and go to: `https://localhost:47990`
2. Accept the self-signed certificate warning
3. Default login:
   - **Username**: `admin`
   - **Password**: Generate one with:
     ```bash
     echo -n "your_secure_password" | openssl dgst -sha256
     ```
   - Copy the hash and paste it in the password field

### 3. Add Applications
In the web UI, go to "Applications" and add:

**For full desktop access:**
- **Name**: `Desktop`
- **Command**: `gnome-session` (for GNOME) or `startx` (for X11)
- **Working Directory**: `/home/your_username`
- **Image Path**: Leave empty or add desktop icon

**For specific applications:**
- **Name**: `Firefox`
- **Command**: `firefox`
- **Working Directory**: `/home/your_username`

### 4. Network Configuration (Important!)

#### Local Network Only:
No additional setup needed if both machines are on the same network.

#### Remote Access (Internet):
Configure your router to forward these ports to your work machine:

- **TCP**: `47989` (HTTPS), `47990` (Web UI)
- **UDP**: `47998`, `47999`, `48000`, `48002`, `48010`

**Security Warning**: Only do this if you understand the security implications. Consider using a VPN instead.

## 📱 Client Setup (Home Laptop - Moonlight)

### 1. Launch Moonlight
```bash
moonlight
# Or use the desktop entry from your application menu
```

### 2. Add Your Server

#### Local Network:
1. Click "Add PC manually"
2. Enter your work machine's **local IP address** (e.g., `192.168.1.100`)
3. Click "Add PC"

#### Remote Access:
1. Click "Add PC manually"
2. Enter your **public IP address** or **DDNS hostname**
3. Click "Add PC"

**Find your work machine's local IP:**
```bash
ip addr show | grep "inet " | grep -v 127.0.0.1
```

### 3. Pairing Process
1. Moonlight will show a 4-digit PIN
2. On your work machine, check the Sunshine web UI or terminal output
3. The PIN should appear automatically in Sunshine
4. If not, go to Sunshine web UI → "PIN" section and enter the PIN
5. Click "Pair" in both applications

### 4. Test Connection
1. After pairing, you should see your work machine in Moonlight
2. Click on it to see available applications
3. Click "Desktop" or any specific application to start streaming

## 🔧 Troubleshooting

### Connection Issues

**Can't find server:**
- Ensure both machines are on the same network (for local setup)
- Check firewall settings on work machine:
  ```bash
  # Allow Sunshine through firewall (if using ufw)
  sudo ufw allow 47989/tcp
  sudo ufw allow 47990/tcp
  sudo ufw allow 47998:48010/udp
  ```

**Pairing fails:**
- Restart Sunshine service:
  - **Linux**: `systemctl --user restart sunshine`
  - **macOS**: `launchctl unload ~/Library/LaunchAgents/org.homebrewformulas.sunshine.plist && launchctl load ~/Library/LaunchAgents/org.homebrewformulas.sunshine.plist`
- Clear Moonlight's PC list and re-add the server
- Check Sunshine logs:
  - **Linux**: `journalctl --user -u sunshine -f`
  - **macOS**: Check Console.app or `log stream --predicate 'subsystem == "org.homebrewformulas.sunshine"'`

**Black screen or poor performance:**
- Ensure your work machine has hardware acceleration enabled
- Check Sunshine settings in web UI:
  - Set encoder to `nvenc` (NVIDIA) or `amd` (AMD)
  - Adjust bitrate (start with 20 Mbps for 1080p)
  - Try different resolutions

### Network Performance

**For best performance:**
- **Local network**: Use wired gigabit Ethernet on both ends
- **Remote**: Ensure at least 25 Mbps upload on work end, 25 Mbps download on home end
- **WiFi**: Use 5GHz band, avoid 2.4GHz

**Quality settings in Moonlight:**
- **Resolution**: Start with 1080p, adjust based on performance
- **FPS**: 60 FPS for gaming, 30 FPS sufficient for desktop work
- **Bitrate**: Auto-adjust, or manually set 20-50 Mbps based on connection

## 🍎 macOS-Specific Setup

### Additional macOS Requirements
Sunshine on macOS requires additional permissions that must be granted manually:

1. **Screen Recording Permission**:
   - Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Screen Recording**
   - Add and enable `sunshine` (you may need to browse to `/nix/store/.../bin/sunshine`)

2. **Accessibility Permission**:
   - Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
   - Add and enable `sunshine` for input control

3. **Microphone Permission** (optional):
   - Go to **System Preferences** → **Security & Privacy** → **Privacy** → **Microphone**
   - Add `sunshine` if you want audio streaming

### macOS Firewall
If macOS firewall is enabled:
- Go to **System Preferences** → **Security & Privacy** → **Firewall** → **Firewall Options**
- Add `sunshine` and set to "Allow incoming connections"

### macOS Service Management
```bash
# Check if service is loaded:
launchctl list | grep sunshine

# Manual start/stop:
launchctl load ~/Library/LaunchAgents/org.homebrewformulas.sunshine.plist
launchctl unload ~/Library/LaunchAgents/org.homebrewformulas.sunshine.plist
```

## 🛡️ Security Best Practices

1. **Change default password** immediately after first setup
2. **Use VPN** instead of port forwarding for remote access
3. **Keep Sunshine updated** regularly
4. **Monitor access logs** in Sunshine web UI
5. **Consider network isolation** for work machine if possible

## 📊 Performance Optimization

### Work Machine (Server):
```bash
# Ensure GPU drivers are up to date
# For NVIDIA:
nvidia-smi

# For AMD:
rocm-smi
```

### Network optimization in Sunshine web UI:
- **Encoder**: Hardware (NVENC/AMF) > Software
- **Framerate**: Match your monitor's refresh rate
- **Bitrate**: Start conservative, increase if quality is poor

### Moonlight Client Settings:
- **Hardware decoding**: Enable if available
- **VSync**: Disable for lower latency
- **Game optimization**: Enable for better gaming performance

## ✅ Quick Checklist

**Server (Work Machine):**
- [ ] Sunshine service running
- [ ] Web UI accessible at localhost:47990
- [ ] Password set and secure
- [ ] Applications configured
- [ ] Firewall configured (if needed)

**Client (Home Laptop):**
- [ ] Moonlight installed and running
- [ ] Server added and paired successfully
- [ ] Can see and launch applications
- [ ] Performance is acceptable

**Network:**
- [ ] Both machines can ping each other
- [ ] Required ports are open
- [ ] Connection quality is stable

---

## 🆘 Need Help?

**Check logs:**
```bash
# Sunshine logs:
journalctl --user -u sunshine -f

# System graphics info:
lspci | grep -i vga
```

**Test network connectivity:**
```bash
# From home laptop, test connection to work machine:
nc -zv <work-machine-ip> 47989
```

**Sunshine config location:**
- Config: `~/.config/sunshine/sunshine.conf`
- Logs: Check with `journalctl --user -u sunshine`