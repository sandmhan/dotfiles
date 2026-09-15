{ legcord }:
legcord.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./wayland-screencast.patch ];
})
