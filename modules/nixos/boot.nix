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

  # Newest kernel. Not optional here: the Ryzen 7 250's iGPU and the Legion's
  # sensors/wifi all want recent amdgpu + platform drivers, and Blackwell
  # (RTX 5060) needs a kernel new enough for the 575+ NVIDIA modules.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # systemd in the initrd — needed to unlock LUKS with a proper console, and
  # it gives you a usable emergency shell when something goes wrong at boot.
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
