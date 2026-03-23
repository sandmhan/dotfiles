# W-SOFLE Wireless Keyboard - Firmware Flashing Guide

## Overview

The W-SOFLE is a wireless split keyboard based on the Sofle design that runs QMK firmware and is Vial-compatible. This guide covers how to flash custom firmware similar to the Silakka 54 workflow.

## Hardware Information

- **Model**: W-SOFLE (Sofle-Based 2.4G Wireless)
- **Wireless Module**: MTKB
- **Connectivity**: 2.4G wireless + USB-C wired
- **Firmware**: QMK with Vial support
- **Bootloader**: Accessible via Vial "Bootloader" button

## Key Differences from Wired Keyboards (Silakka 54)

| Feature | Silakka 54 (Wired) | W-SOFLE (Wireless) |
|---------|--------------------|--------------------|
| Flashing Mode | Any time | **Must be in USB wired mode** |
| Reset Method | Physical button | Vial "Bootloader" button |
| Connectivity | USB only | 2.4G + USB (switch for flashing) |

## Critical Requirements for Flashing

⚠️ **IMPORTANT**: Firmware flashing only works in **wired mode**

1. **Connect keyboard via USB-C cable** (not 2.4G receiver)
2. **Switch keyboard to wired mode** if it has a mode switch
3. **Use the USB cable that supports data** (not charging-only)

## Flashing Workflow

### Prerequisites

```bash
# Install QMK tools (already in your nix config)
nix-shell -p qmk

# Verify QMK installation
qmk doctor
```

### Method 1: Using Vial Bootloader Button (Recommended)

1. **Setup bootloader key in Vial**:
   - Open [vial.rocks](https://vial.rocks) in Chrome
   - Connect W-SOFLE via USB cable
   - Map "Bootloader" function to an unused key
   - Apply the keymap

2. **Enter bootloader mode**:
   - Press the key you mapped to "Bootloader"
   - Keyboard should disconnect and reappear as bootloader device

3. **Flash firmware**:
   ```bash
   # Option A: Flash existing firmware
   qmk flash -kb sofle/rev1 -km default

   # Option B: Flash custom keymap (if created)
   qmk flash -kb sofle/rev1 -km your_custom_keymap
   ```

### Method 2: Alternative Bootloader Entry

If Vial bootloader button doesn't work:

```bash
# Method A: ESC key method
# 1. Disconnect USB cable
# 2. Hold ESC key while reconnecting cable

# Method B: Check for physical reset button
# Some W-SOFLE variants may have a small reset button
```

### Verification

```bash
# Check if bootloader is detected
lsusb | grep -i "bootloader\|atmel\|dfu"

# Or use QMK to detect
qmk doctor
```

## Building Custom Firmware

### Option A: Use existing Sofle configuration

```bash
# Clone QMK repository (if not already done)
qmk setup

# Build for sofle rev1 (most common)
qmk compile -kb sofle/rev1 -km default
```

### Option B: Create custom keymap

```bash
# Create custom keymap directory
mkdir -p ~/qmk_firmware/keyboards/sofle/keymaps/sandmhan_wsofle

# Copy your Silakka 54 keymap as starting point
cp /home/sandmhan/dotfiles/configs/keyboard/silakka54/sandmhan/keymap.c \
   ~/qmk_firmware/keyboards/sofle/keymaps/sandmhan_wsofle/

# Edit and compile
qmk compile -kb sofle/rev1 -km sandmhan_wsofle
```

## Troubleshooting

### Common Issues

1. **"No device found" error**:
   - Ensure keyboard is in USB wired mode
   - Check USB cable supports data (not charging-only)
   - Try different USB port

2. **Bootloader not detected**:
   - Verify Vial bootloader key is mapped correctly
   - Try alternative bootloader entry methods
   - Check if physical reset button exists

3. **Flashing fails**:
   - Don't disconnect during flashing (causes soft brick)
   - Use reliable power source
   - Try different USB cable

### Recovery

If keyboard becomes unresponsive after failed flash:

```bash
# Put into bootloader mode and reflash stock firmware
qmk flash -kb sofle/rev1 -km default
```

## Wireless-Specific Considerations

- **Wireless functionality**: Custom firmware should maintain wireless capabilities
- **Battery management**: Ensure custom firmware doesn't break power management
- **NKRO limitation**: QMK wireless doesn't support full N-Key Rollover
- **Bluetooth vs 2.4G**: W-SOFLE uses 2.4G (not Bluetooth), different from standard QMK wireless

## Testing Your Setup

Before creating custom firmware, test the bootloader functionality:

1. Map Bootloader button in Vial
2. Connect via USB
3. Press bootloader key
4. Check if `lsusb` shows bootloader device
5. If successful, proceed with custom firmware

## Resources

- [QMK Firmware Documentation](https://docs.qmk.fm/)
- [Vial Documentation](https://get.vial.today/)
- [Sofle Keyboard Build Guide](https://josefadamcik.github.io/SofleKeyboard/build_guide.html)
- [QMK Wireless Features](https://docs.qmk.fm/features/wireless)
- [W-SOFLE Product Page](https://pandakb.com/shop/keyboard-kit/w-sofle-split-keyboard-sofle-based-2-4g-wireless-w-usb-receiver-vial-programmabledistributed/)

## Notes

- Firmware built: [Date when you build firmware]
- Working keymap: [Path to your working keymap]
- Bootloader method: [Which method worked for your specific unit]

---

*Last updated: March 16, 2026*
*Location: `/home/sandmhan/dotfiles/configs/keyboard/w-sofle/docs/FLASHING_INSTRUCTIONS.md`*