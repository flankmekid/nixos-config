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

  # Suspend-then-hibernate is pointless without a swap device, and we use zram,
  # so plain suspend it is. Closing the lid suspends; on AC it does nothing.
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
