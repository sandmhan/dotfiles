# W-SOFLE Wireless Keyboard Configuration

## Directory Structure

```
w-sofle/
├── README.md                           # This file
├── QUICK_REFERENCE.md                  # Essential commands
├── docs/
│   ├── FLASHING_INSTRUCTIONS.md        # Complete flashing guide
│   └── 42_KEY_LAYOUT_RESOURCES.md      # 42-key layout resources & examples
└── sandmhan/                           # Custom keymap
    ├── sofle-42-key                    # Current Vial configuration (42-key)
    ├── keymap.c                        # Custom keymap layout (when created)
    ├── config.h                        # Custom configuration (when created)
    └── rules.mk                        # Build rules (when created)
```

## Hardware

- **Model**: W-SOFLE (Sofle-Based 2.4G Wireless) - **Modified to 42-key Corne-style layout**
- **MCU**: Compatible with Sofle QMK firmware
- **Connectivity**: USB-C + 2.4G wireless
- **Layout**: ~~Split 58-key with rotary encoders~~ → **42-key split (switches removed)**

## Current Status

- ✅ **Vial connectivity**: Working (udev rules fixed)
- ✅ **Key remapping**: Available via vial.rocks
- ✅ **42-key modification**: Hardware modified, Vial config created
- ✅ **Basic layout**: Working Corne-style layout in Vial
- 🔄 **Custom firmware**: Ready to test (bootloader button method)
- ⏳ **Optimized keymap**: Room for improvement (see resources)

## Compared to Silakka 54

| Feature | Silakka 54 | W-SOFLE (Modified) |
|---------|------------|---------|
| Layout | 54 keys | ~~58~~ → **42 keys** (Corne-style) |
| Connectivity | USB only | USB + 2.4G wireless |
| Flashing | Anytime | USB wired mode only |
| Philosophy | Standard layout | Minimal keys + layers |
| Current Status | Custom QMK | Vial working, optimization pending |

## Quick Start

1. **Vial configuration**: Connect keyboard, open vial.rocks in Chrome
2. **Test bootloader**: Map "Bootloader" function to test key
3. **Custom firmware**: See QUICK_REFERENCE.md for commands

## Related Files

- **System config**: `/home/sandmhan/dotfiles/configuration.nix` (udev rules)
- **Silakka 54 config**: `/home/sandmhan/dotfiles/configs/keyboard/silakka54/sandmhan/`
- **Home Manager**: QMK package included in desktop profile

---

*Part of sandmhan's dotfiles keyboard configuration*