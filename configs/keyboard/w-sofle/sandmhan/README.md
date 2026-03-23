# W-SOFLE 42-Key Custom Keymap (sandmhan)

## Current Status

✅ **Hardware Modified**: Switches removed to create 42-key Corne-style layout
✅ **Vial Config**: `sofle-42-key` - Working basic layout
⏳ **QMK Custom**: Future custom keymap files

### Current Files

- `sofle-42-key` - Vial configuration (JSON format)
- `README.md` - This file

### Future Files
- `keymap.c` - Main keymap layout (QMK format)
- `config.h` - Custom configuration options
- `rules.mk` - Build rules and features

## Creating Your Custom Keymap

1. **Study 42-key resources** (see `../docs/42_KEY_LAYOUT_RESOURCES.md`)
2. **Test bootloader access first** (see `../QUICK_REFERENCE.md`)
3. **Analyze your current Vial layout**:
   ```bash
   # Your current working layout is in sofle-42-key
   # Study successful 42-key layouts from the resources
   ```
4. **Adapt gradually from your Silakka 54 workflow**:
   - Identify most-used keys from Silakka 54
   - Plan layer access for numbers/symbols
   - Optimize thumb cluster usage
5. **Create QMK version** when ready

## Layout Differences

**Silakka 54**: 54 keys, 3 layers, more keys available
**W-SOFLE (Modified)**: 42 keys, Corne-style 3x5+3, requires efficient layering

### Key Reduction Challenge
- **Lost 12 keys** compared to Silakka 54
- **Must optimize layers** for number/symbol access
- **Thumb cluster critical** for layer switching and modifiers

## Build Command (When Created)

```bash
qmk flash -kb sofle/rev1 -km sandmhan_wsofle
```

---

*Will be populated after testing bootloader and creating custom layout*