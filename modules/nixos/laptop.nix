# ── Legion 5 specifics: power, fans, lid, thermals ────────────────────────────
{ config, pkgs, lib, ... }:
{
  # ── Legion kernel module: exposes fan curves, power modes (Quiet/Balanced/
  #    Performance), battery conservation mode and the keyboard backlight.
  #    Gives you the `legion_cli` / `legion_gui` tools from pkgs.lenovo-legion.
  boot.extraModulePackages = with config.boot.kernelPackages; [ lenovo-legion-module ];
  boot.kernelModules = [ "lenovo-legion-module" ];

  environment.systemPackages = with pkgs; [
    lenovo-legion # legion_gui / legion_cli — fan curves + power modes
    powertop
    acpi
  ];

  # ── Power management.
  # nixos-hardware's common-pc-laptop turns on TLP; we deliberately swap it for
  # power-profiles-daemon, because the Legion exposes a real ACPI
  # `platform_profile` and PPD drives it directly (and Caelestia's power widget
  # talks to PPD, not TLP). Running both at once is a classic way to get
  # nondeterministic CPU behaviour, so TLP is force-disabled.
  services.tlp.enable = lib.mkForce false;
  services.power-profiles-daemon.enable = true;

  # ── Fn+Q → PPD sync. Fn+Q is handled by the firmware: it changes the
  #    lenovo-wmi-gamezone profile (LED: blue = low-power, white = balanced,
  #    red = performance, AC only) but not amd-pmf, so the combined
  #    /sys/firmware/acpi/platform_profile reads "custom" and PPD ignores it.
  #    This forwards each Fn+Q change to PPD, which then sets every driver
  #    (amd-pmf included) and keeps Caelestia's power widget in sync.
  #    The other direction (PPD → Fn+Q LED) already works on its own.
  systemd.services.fnq-profile-sync = {
    description = "Forward Legion Fn+Q power mode changes to power-profiles-daemon";
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.power-profiles-daemon.package ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      ExecStart = pkgs.writers.writePython3 "fnq-profile-sync" { doCheck = false; } ''
        import glob
        import os
        import select
        import subprocess
        import sys

        # gamezone's names → PPD's. It reports red as "balanced-performance".
        TO_PPD = {
            "low-power": "power-saver",
            "balanced": "balanced",
            "balanced-performance": "performance",
            "performance": "performance",
        }

        path = next((d + "/profile" for d in glob.glob("/sys/class/platform-profile/*")
                     if open(d + "/name").read().strip() == "lenovo-wmi-gamezone"), None)
        if path is None:
            sys.exit("lenovo-wmi-gamezone platform profile not found")

        fd = os.open(path, os.O_RDONLY)
        poller = select.poll()
        poller.register(fd, select.POLLPRI | select.POLLERR)

        def read():
            os.lseek(fd, 0, 0)
            return os.read(fd, 64).decode().strip()

        # Only react to changes, so PPD's own restore at boot wins.
        last = read()
        while True:
            # sysfs wakes us on a change; the timeout is a fallback in case
            # the driver doesn't notify.
            poller.poll(2000)
            cur = read()
            if cur == last:
                continue
            last = cur
            want = TO_PPD.get(cur)
            if want is None:
                continue
            ppd = subprocess.run(["powerprofilesctl", "get"],
                                 capture_output=True, text=True).stdout.strip()
            if ppd != want:
                subprocess.run(["powerprofilesctl", "set", want])
      '';
    };
  };

  # Plain suspend. Hibernation is possible (hardware-configuration.nix has a
  # 16G swap partition) but would also need boot.resumeDevice.
  # Lid closed always means asleep, on battery or on AC. The alternative
  # ("ignore" on AC) has a nasty failure mode: logind only evaluates the lid
  # event at the moment it fires, so closing the lid while plugged in and THEN
  # unplugging leaves the machine running in your bag.
  #
  # Docked is the deliberate exception — when an external monitor is attached
  # you are closing the lid *in order to* use that monitor.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    # Do not kill a long build when you log out of a TTY.
    KillUserProcesses = false;
  };

  # Modern AMD laptops use s2idle rather than S3; make it explicit so a BIOS
  # update flipping the default doesn't silently wreck standby battery drain.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # Thermal management for the AMD SoC.
  services.thermald.enable = false; # Intel-only; the AMD path is amd-pstate + PPD
  hardware.acpilight.enable = true; # backlight control without root

  # SSD maintenance.
  services.fstrim.enable = true;

  # Don't let a completely dead battery corrupt btrfs.
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 7;
    percentageAction = 4;
    criticalPowerAction = "PowerOff";
  };
}
