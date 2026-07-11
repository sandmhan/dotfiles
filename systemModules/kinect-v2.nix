{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.meridianKinect;
  kinectRules = ''
    # Microsoft Kinect v2 bootloader and runtime interfaces.
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02c4", GROUP="${cfg.group}", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02d8", GROUP="${cfg.group}", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02d9", GROUP="${cfg.group}", MODE="0660", TAG+="uaccess"
  '';
in
{
  options.hardware.meridianKinect = {
    enable = lib.mkEnableOption "Microsoft Kinect v2 userspace access";

    group = lib.mkOption {
      type = lib.types.strMatching "^[a-z_][a-z0-9_-]*$";
      default = "video";
      description = "Group granted access to Kinect v2 USB interfaces.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "usbcore.usbfs_memory_mb=64" ];
    users.groups.${cfg.group} = { };
    services.udev.extraRules = kinectRules;
  };
}
