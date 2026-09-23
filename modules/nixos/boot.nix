# ── Boot, kernel, initrd ──────────────────────────────────────────────────────
{ pkgs, lib, ... }:
{
  # systemd-boot: simpler than GRUB and gives you the generation menu for free.
  boot.loader.systemd-boot = {
    enable = true;
    # Don't let 40 generations of kernels fill the 1G ESP.
    configurationLimit = 15;
    # Stops a stray keypress at the menu from silently booting an old kernel.
    editor = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # LTS kernel. The NVIDIA module often fails to build on the newest kernel.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;

  # systemd in the initrd: a usable emergency shell if boot fails.
  boot.initrd.systemd.enable = true;


  # Quiet, flicker-free boot into the Hyprland greeter.
  boot.kernelParams = [ "quiet" "splash" "rd.udev.log_level=3" ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.plymouth.enable = true;

  # Compressed RAM swap instead of a swap partition. With 16-32G of RAM this is
  # faster than swapping to disk and avoids putting swap inside (or outside) the
  # LUKS container. Note: this rules out hibernation — see README if you want it.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Let a burst of compilation swap rather than OOM-kill your editor.
  boot.kernel.sysctl = {
    "vm.swappiness" = 180; # sensible when swap is RAM-backed (zram), not a disk
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # Userspace OOM killer — kills the runaway tab/compiler before the machine
  # locks up for two minutes. Much better desktop behaviour than the kernel's.
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
