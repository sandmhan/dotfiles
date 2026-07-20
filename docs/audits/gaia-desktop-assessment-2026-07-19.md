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
- `home/modules/notifications.nix` owns SwayNotificationCenter, its Waybar and
  Sway controls, and low-priority desktop state notifications.
- `home/modules/screenshot.nix` owns the Rofi screenshot/recording workflow.
- `home/modules/theming.nix` generates runtime-switchable Sway, Waybar,
  SwayNotificationCenter, Rofi, terminal, and tmux colors.

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

### SwayNotificationCenter integration

SwayNotificationCenter is now the declarative owner of
`org.freedesktop.Notifications`. Discord/Legcord, Element, browsers, and other
applications using the desktop notification protocol require no per-app wiring.
The integration adds:

- `Ctrl+Alt+N` and a left-clickable Waybar icon to toggle notification history.
- Right-clicking the Waybar icon to toggle do-not-disturb mode.
- Six-second normal, three-second low-priority, and persistent critical
  notification timeouts.
- Grouping, notification actions, inline replies when an application supports
  them, 2FA-code actions, and a compact 400-pixel popup width.
- Runtime Base16 theme updates through the existing `theme-switch` command.

A supervised user service reports only meaningful state transitions: AC power
connected or disconnected, a Wi-Fi connection established, and a newly
connected Bluetooth device. It also warns once at 15% battery and raises a
persistent critical alert at 5% while discharging. It does not report periodic
status, Wi-Fi disconnects, or Bluetooth disconnects. Successful screenshots,
recordings, theme changes, and routine system events use low urgency to reduce
interruption; failures and battery warnings retain higher urgency.

## Prioritized findings

### Notification daemon evaluation

The pinned package set and Home Manager input support all four practical Sway
candidates declaratively. Stylix also has Home Manager targets for each, so no
out-of-band package installation or hand-maintained configuration is required.

| Daemon | Pinned version | Strengths | Tradeoffs | Gaia fit |
| --- | --- | --- | --- | --- |
| SwayNotificationCenter | 0.12.6 | Notification history panel, grouped notifications, actions and inline replies, persistent do-not-disturb state, CSS styling, hot reload, and an upstream Waybar integration | Largest dependency/UI surface because it uses GTK4 and libadwaita; third-party GTK themes can require CSS adjustments | Best fit when missed-notification recovery and a visible control center matter |
| Dunst | 1.13.2 | Mature rules, scripts, urgency handling, pause levels, replayable history, `dunstctl`, and both Wayland and X11 support | History is replay-oriented rather than a browsable panel; carries X11 support that Gaia does not need | Best balanced fallback if SwayNotificationCenter feels too heavy |
| Mako | 1.11.0 | Small Wayland-native daemon designed for Sway, straightforward rules, actions, runtime control through `makoctl`, and D-Bus activation | No full notification-center panel; less useful when a notification disappears before it is read | Best minimalist choice |
| Fnott | 1.8.0 | Small wlroots-native, keyboard-driven daemon with urgency, actions, pause control, and simple INI configuration | Implements only part of the desktop notification specification and has the least rich history/discovery surface | Best only when minimal footprint is the overriding requirement |

SwayNotificationCenter is the recommended first trial for Gaia. The existing
desktop audit already identifies discoverability as a weakness, and its panel,
notification count, do-not-disturb control, and upstream Waybar protocol address
that directly. A clean implementation should use `services.swaync`, add a
Waybar notification module, bind one key to the control center, and extend the
runtime theme switcher to reload its generated CSS. Only one notification daemon
may own `org.freedesktop.Notifications`, so the other three must remain disabled.

### Priority 0: choose an idle-lock policy

1. swayidle powers displays off after ten minutes but does not lock first and
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

The pre-existing NVF rename/deprecation warnings observed during the initial
desktop checkpoint were resolved in the subsequent NVF maintenance work.

The notification checkpoint additionally passed:

```text
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage --show-trace
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage --show-trace
nix build --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
check-jsonschema --schemafile <pinned-swaync-schema> <generated-config.json>
shellcheck <generated-event-notifier> <generated-screenshot-rofi> <generated-theme-switch>
sway --validate -c <generated Home Manager Sway config>
deadnix home/modules/notifications.nix home/modules/screenshot.nix home/modules/theming.nix
statix check home/modules/notifications.nix
statix check home/modules/screenshot.nix
```

`statix check home/modules/theming.nix` continues to report its pre-existing
repeated dotted-key style warnings; the generated module evaluates and builds.

## Suggested next phase

1. Decide the idle-lock and before-sleep policy.
2. Add fullscreen and scratchpad-recall bindings plus a discoverable key guide.
3. Correct the Waybar height and remove inactive modules.
4. Collect `app_id`/class evidence from applications that still need automatic
   floating rules after using the new manual toggle.
