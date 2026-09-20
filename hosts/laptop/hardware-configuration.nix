# ┌───────────────────────────────────────────────────────────────────────────┐
# │  PLACEHOLDER — REPLACE THIS FILE ON THE REAL MACHINE.                     │
# │                                                                           │
# │  This is a hand-written stub so the flake evaluates before you own the     │
# │  hardware. It is NOT a substitute for the generated file. During install:  │
# │                                                                           │
# │    sudo nixos-generate-config --no-filesystems --root /mnt                 │
# │    cp /mnt/etc/nixos/hardware-configuration.nix \                          │
# │       /mnt/<repo>/hosts/laptop/hardware-configuration.nix                  │
# │                                                                           │
# │  --no-filesystems matters: disko.nix already declares every mount, and     │
# │  without the flag you get two conflicting definitions of fileSystems."/".  │
# └───────────────────────────────────────────────────────────────────────────┘
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Typical for a modern AMD laptop with an NVMe drive and a USB keyboard/dock.
  # The generated file will replace these with what actually got probed.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Filesystems are intentionally absent — disko.nix owns them.

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
