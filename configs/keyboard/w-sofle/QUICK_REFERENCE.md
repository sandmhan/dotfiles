# W-SOFLE Quick Reference

## Essential Commands

```bash
# Check QMK setup
qmk doctor

# Build default Sofle firmware
qmk compile -kb sofle/rev1 -km default

# Flash firmware (after entering bootloader mode)
qmk flash -kb sofle/rev1 -km default

# Flash custom keymap
qmk flash -kb sofle/rev1 -km sandmhan_wsofle
```

## Bootloader Entry

1. Connect via USB cable (not wireless)
2. Press Vial-mapped "Bootloader" key
3. Verify with: `lsusb | grep -i "bootloader\|atmel\|dfu"`

## Quick Steps

1. **USB wired mode** ✅
2. **Map bootloader key in Vial** ✅
3. **Press bootloader key** ✅
4. **Flash with QMK** ✅

## Emergency Reset

```bash
# If keyboard becomes unresponsive
qmk flash -kb sofle/rev1 -km default
```

---
*See FLASHING_INSTRUCTIONS.md for complete guide*