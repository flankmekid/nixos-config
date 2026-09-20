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
  # It is also what makes TPM2 auto-unlock possible at all.
  boot.initrd.systemd.enable = true;

  # ── TPM2, used to unlock the disk without typing a passphrase.
  #
  # ⚠ Security note, because this interacts with the decision to run without
  # Secure Boot: sealing the LUKS key to the TPM protects you against someone
  # removing the SSD and reading it in another machine (the realistic theft
  # case). It does NOT protect against someone stealing the laptop intact and
  # booting a USB stick — with Secure Boot off, PCR 7 looks the same to the
  # TPM either way, so it would release the key. If you later want both
  # convenience and that guarantee, add lanzaboote and re-enrol against PCR 7
  # with Secure Boot on. Your passphrase always remains as a fallback.
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };
  environment.systemPackages = [ pkgs.tpm2-tools ];

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
