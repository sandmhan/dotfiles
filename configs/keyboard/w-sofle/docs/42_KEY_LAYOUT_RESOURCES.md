# 42-Key Split Keyboard Layout Resources

## Overview

This document contains curated resources for designing effective 42-key split keyboard layouts, particularly for your modified W-SOFLE configured as a Corne-style keyboard.

Your current setup: **W-SOFLE with switches removed → 42-key Corne-like layout**

## Philosophy of 42-Key Layouts

### Core Principles

**Ergonomic Movement Reduction**: [Small keyboards reduce hand motions](https://www.justinmklam.com/posts/2026/02/beginners-guide-split-keyboards/) for long typing sessions. The philosophy is that you should never have to reach farther than one adjacent key.

**Layer-Based Accessibility**: [For 40% keyboards, layers are key to achieving accessibility](https://mattgemmell.scot/the-corne-keyboard/) with minimum finger travel. You can define up to 32 layers in QMK.

**Thumb Utilization**: [Move work from weak pinkies to strong thumbs](https://mark.stosberg.com/markstos-corne-3x5-1-keyboard-layout/) without overloading them. Space, Enter, Backspace, and layer keys belong in thumb clusters.

### Layout Structure

**3x5+3 Configuration**:
- 6 columns x 3 rows + 3 thumb keys per hand = 42 total keys
- Represents a significant departure from traditional keyboards
- [Common notation: 6x3+3](https://windmaomao.medium.com/42-keys-keyboard-layout-7b0af213f421)

## Excellent GitHub Keymap Repositories

### 1. Comprehensive Guides

**[Elil50/crkbd_QMK](https://github.com/Elil50/crkbd_QMK)** - Comprehensive Corne split keyboard guide + QMK keymap (optimised for coding and typing)
- Easy and fast layout for beginners
- Detailed documentation
- Coding-optimized

### 2. Specialized Professional Layouts

**[ferrance/dizave42](https://github.com/ferrance/dizave42)** - Keymap for crkbd
- Accommodates both legal writing and programming
- Five layers: colemak, nav, numbers, law, and functions
- Professional workflow optimized

**[kip93/qmk-crkbd](https://github.com/kip93/qmk-crkbd)** - Custom firmware for Corne keyboard
- 2 "modes": Typing and Gaming
- Typing mode (first 3 layers) for general use and coding
- Gaming mode (last 2 layers) for split keyboard gaming

### 3. Alternative Layout Approaches

**[precompute/keyboard-keymap-QMK](https://github.com/t-e-r-m/keyboard-keymap-QMK)** - Keymap for Corne keyboard (crkbd)
- Colemak-focused layout
- Demonstrates planning for 42-key usability

## Popular Layout Strategies

### 1. Markstos Layout

**[Markstos Corne 42-key layout](https://mark.stosberg.com/markstos-corne-3x5-1-keyboard-layout/)**
- Updated February 2025
- Published QMK userspace repo
- Uses 3 rows x 5 columns for common keys
- Outer sixth column for rarely used/optional keys

### 2. Home Row Mods vs One-Shot Mods

**Home Row Mods**: [All main modifiers on homerow](https://thrly.com/blog/thoughts-on-customising-a-split-keyboard-layout/)
- Minimizes movement for programming
- Timing-sensitive and requires configuration
- Can slow down typing initially

**One-Shot Modifiers**: [Alternative approach](https://www.justinmklam.com/posts/2025/07/36-key-layout/)
- No timing issues
- Requires dedicated keys (challenging on 36-key, feasible on 42-key)

### 3. Layer Design Patterns

**Common Layer Structure**:
1. **Base Layer** - QWERTY/Colemak/Dvorak
2. **Navigation Layer** - Arrows, home/end, page up/down
3. **Number/Symbol Layer** - Numbers, symbols, function keys
4. **System Layer** - Media keys, system functions

## Key Resources and Tools

### Layout Databases

**[KeymapDB](https://keymapdb.com/)** - Database of keymaps for programmable keyboards
- Browse real user configurations
- Filter by key count and keyboard type
- [42-key specific layouts](https://keymapdb.com/page/8/)

### Educational Articles

**[The Corne Keyboard — Matt Gemmell](https://mattgemmell.scot/the-corne-keyboard/)**
- Personal journey with 42-key layouts
- Practical tips and insights

**[42 keys keyboard layout](https://windmaomao.medium.com/42-keys-keyboard-layout-7b0af213f421)**
- Detailed analysis of 42-key design decisions

**[Transitioning to a 36-Key Layout](https://www.justinmklam.com/posts/2025/07/36-key-layout/)**
- Insights applicable to 42-key layouts
- Transition strategies from larger layouts

## Performance and Benefits

### Reported Improvements

- **Typing Speed**: [Users report increases from 65 WPM to 85 WPM](https://mattgemmell.scot/the-corne-keyboard/)
- **Sustained Speed**: 100-120 WPM achievable with well-designed layouts
- **Ergonomics**: Reduced finger travel and hand movement

### Modern QMK Features

**Autoshift**: Automatic capital letters by holding keys longer
**Combos**: Multiple keys pressed simultaneously for additional functions
**Layer Switching**: Efficient access to all required keys
**Tap-Hold Functions**: Single keys with dual purposes

## Your Current Layout Analysis

Based on your Vial configuration (`sofle-42-key`):

### Current Base Layer
```
TAB  Q  W  E  R  T     Y  U  I  O  P  \
ESC  A  S  D  F  G     H  J  K  L  ;  '
CTRL Z  X  C  V  B     N  M  ,  .  /  =
         ALT MO(1) LSHFT   ENT SPC BSPC
```

### Recommended Improvements

1. **Consider Home Row Mods** on A/S/D/F and J/K/L/; positions
2. **Optimize Thumb Cluster** - current: ALT, Layer, LSHIFT / ENTER, SPACE, BSPACE
3. **Develop Symbol/Number Layer** (currently mostly transparent)
4. **Add Navigation Layer** for arrows and function keys

## Getting Started

1. **Study successful layouts** from the GitHub repos above
2. **Try different approaches** using your Vial configuration
3. **Iterate gradually** - don't change everything at once
4. **Focus on your workflow** - coding vs writing vs gaming
5. **Practice consistently** - muscle memory takes 2-4 weeks

## QMK Technical Notes

- Corne keyboards are called `crkbd` in QMK
- Your W-SOFLE uses `sofle` keyboard definition with custom layout
- Layer switching: Use `MO(n)` for momentary, `TG(n)` for toggle
- Consider `LT(layer, keycode)` for tap-hold layer switching

---

*Compiled: March 2026 | For: Modified W-SOFLE 42-key layout*