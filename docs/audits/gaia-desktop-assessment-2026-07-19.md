---
title: Gaia Desktop Assessment 2026-07-19
status: draft
---

# Gaia Desktop Assessment 2026-07-19

## Scope

This audit covers the active Gaia desktop path exported as
`homeConfigurations.sandmhan`: Sway, Waybar, Rofi, swayidle/swaylock, window
placement, and screenshot/recording workflows. It uses the repository modules,
the evaluated Home Manager configuration, and the live Sway session as evidence.

The current stack is deliberately retained. Ly remains the display manager,
Sway remains the compositor, and automatic tiling remains enabled.

## Current topology

- `home/profiles/desktop.nix` selects the desktop features.
- `home/modules/desktop.nix` owns Rofi, swaylock, and desktop applications.
- `home/modules/wm.nix` owns Sway, Waybar, swayidle, window assignments, and
  session startup.
- `home/modules/screenshot.nix` owns the Rofi screenshot/recording workflow.
- `home/modules/theming.nix` generates runtime-switchable Sway, Waybar, and Rofi
  colors.

The live session uses Sway 1.12 and Waybar 0.15.0 on the internal `eDP-1`
display at 2256x1504 with scale 2.

## Improvements completed in this audit

### Focused-window floating controls

The generated Sway configuration previously had no focused-window floating
toggle. It now provides:

- `Alt+Shift+Space`: toggle the focused window between tiled and floating.
- `Alt+Space`: move focus between the tiled and floating layers.

This provides an immediate escape hatch for applications whose layouts do not
work well when tiled. App-specific rules should be added only after collecting
the relevant Wayland `app_id` or XWayland class; broad automatic floating rules
would make normal windows harder to manage.

### Screenshot clipboard integration

All image choices in `screenshot-rofi` now save a timestamped PNG and copy that
final PNG to the Wayland clipboard as `image/png`:

- Fullscreen
- Region
- Window
- Fullscreen (edit)
- Region (edit)

Edited captures use Swappy's output-file support, so the annotated result is
what reaches the clipboard. Canceling Rofi or Slurp exits without creating an
empty capture. Screen-recording behavior is unchanged.

## Prioritized findings

### Priority 0: choose an idle-lock and notification policy

1. No notification daemon currently owns `org.freedesktop.Notifications`.
   `notify-send` is used by the screenshot and recording workflow, but neither
   Dunst nor Mako is enabled. Evaluate Dunst, Mako, and SwayNotificationCenter,
   then enable one declaratively.
2. swayidle powers displays off after ten minutes but does not lock first and
   has no `before-sleep` lock event. This preserves long-running work but leaves
   the resumed session unlocked. A proposed policy is to lock at ten minutes,
   power displays off shortly afterward, and run `swaylock -f` before sleep.
   Locking does not suspend user jobs.

### Priority 1: complete the core Sway interaction surface

1. Add an explicit fullscreen toggle; none is currently generated.
2. The move mode can send a window to the scratchpad, but there is no binding to
   show the scratchpad again.
3. Consider a small Rofi keybinding reference so modal move, resize, session,
   floating, layout, and scratchpad controls are discoverable.
4. Enable Home Manager's Sway configuration check after confirming it handles
   the runtime theme include. `checkConfig` is currently disabled, although the
   built configuration passes `sway --validate` in this audit.

### Priority 1: correct and simplify Waybar

1. Waybar reports that the requested 16-pixel height is below the 24-pixel
   minimum required by its modules and silently renders at 24 pixels. Configure
   24 explicitly.
2. The MPD module is displayed even though the Home Manager MPD service is
   disabled. Remove it unless an external MPD server is intentionally used.
3. Waybar is launched directly by Sway and has no user service supervision.
   Evaluate Home Manager's systemd integration for automatic recovery while
   preserving the runtime theme reload behavior.
4. The bar is restricted to `eDP-1` and `DP-4`. Revisit this if docks or monitors
   use changing connector names.
5. The unused `custom/hello-from-waybar` module and the large commented duplicate
   bar block can be removed in a cleanup-only commit.

### Priority 2: improve Rofi and laptop controls

1. Rofi currently has only location and theme configuration. Evaluate icons,
   fuzzy matching, clearer mode labels, and a clipboard-history mode.
2. Add a backlight control or indicator; Gaia exposes `amdgpu_bl1` but Waybar has
   no backlight module.
3. Consider a power-profile indicator so the automatic AC/battery policy is
   visible without running `powerprofilesctl`.
4. The `Print` binding still opens a direct region-to-Swappy flow, while
   `Alt+S` opens the complete menu. Decide whether both entry points should share
   the same save-and-copy behavior.

### Priority 2: revisit startup and tiling policy

1. Sway starts Alacritty and Legcord on every login. Make these opt-in if a clean
   workspace is preferable or if application startup interferes with session
   restoration.
2. `autotiling` changes split orientation automatically. Keep the manual
   floating escape hatch, then collect specific problematic applications before
   adding narrowly scoped window rules.
3. Alt is both the Sway modifier and a common application menu modifier. Retain
   it for now, but include Super in any future keymap comparison.

## Validation evidence

The implementation checkpoint passed:

```text
nix build --dry-run .#homeConfigurations.sandmhan.activationPackage --show-trace
nix build .#homeConfigurations.sandmhan.activationPackage --no-link
nixfmt --check home/modules/wm.nix home/modules/screenshot.nix
deadnix home/modules/wm.nix home/modules/screenshot.nix
statix check home/modules/wm.nix
statix check home/modules/screenshot.nix
shellcheck <generated screenshot-rofi>
sway --validate -c <generated Home Manager Sway config>
```

The Home Manager build emits pre-existing NVF rename/deprecation warnings. They
are unrelated to this desktop checkpoint and should be handled in the NVF work
stream.

## Suggested next phase

1. Select and configure a notification daemon.
2. Decide the idle-lock and before-sleep policy.
3. Add fullscreen and scratchpad-recall bindings plus a discoverable key guide.
4. Correct the Waybar height and remove inactive modules.
5. Collect `app_id`/class evidence from applications that still need automatic
   floating rules after using the new manual toggle.
