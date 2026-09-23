# ── Host: laptop (Lenovo Legion 5, Ryzen 7 250 / Radeon 780M + RTX 5060) ──────
# Everything host-SPECIFIC lives here. Everything reusable lives in ../../modules.
{ ... }:
{
  imports = [
    # Copied from /etc/nixos/hardware-configuration.nix after the graphical
    # install. It declares the disks, so no disko here.
    ./hardware-configuration.nix

    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/dev.nix
    ../../modules/nixos/security.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/apps.nix
    ../../modules/nixos/packages.nix
  ];

  networking.hostName = "laptop";

  # Set at first install and then LEAVE IT — it is not "the version to upgrade
  # to", it pins state-format defaults so upgrades don't silently migrate data.
  system.stateVersion = "26.05";
}
