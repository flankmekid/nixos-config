# ── Nix itself, locale, users, networking ─────────────────────────────────────
{ config, pkgs, lib, ... }:
{
  # ── Nix daemon settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Parallelism — the Ryzen 7 250 is 8C/16T, so let Nix actually use it.
    max-jobs = "auto";
    # Deduplicate identical files in the store; saves a lot on a laptop SSD.
    auto-optimise-store = true;
    # Your user can use the daemon without sudo for e.g. `nix build`.
    trusted-users = [ "root" "dawid" ];
    # Binary caches. Hyprland's own cache means you don't compile the compositor.
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Garbage-collect weekly, keeping 2 weeks of generations. Without this a
  # rolling flake setup will quietly eat 100+ GB.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Makes `nixos-rebuild` show a diff of what actually changed on every switch.
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff \
        /run/current-system "$systemConfig" || true
    '';
  };

  # ── Unfree bits (NVIDIA driver, Spotify, Steam, Zen, …)
  nixpkgs.config.allowUnfree = true;

  # ── Locale / time — Bucharest, English UI, Romanian formats
  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ro_RO.UTF-8";
    LC_IDENTIFICATION = "ro_RO.UTF-8";
    LC_MEASUREMENT = "ro_RO.UTF-8";
    LC_MONETARY = "ro_RO.UTF-8";
    LC_NAME = "ro_RO.UTF-8";
    LC_NUMERIC = "ro_RO.UTF-8";
    LC_PAPER = "ro_RO.UTF-8";
    LC_TELEPHONE = "ro_RO.UTF-8";
    LC_TIME = "ro_RO.UTF-8";
  };
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ro_RO.UTF-8/UTF-8"
  ];

  # US + Romanian layouts; toggle with both Alt keys. Hyprland reads this too
  # (see home/hyprland.nix, which mirrors it for the Wayland session).
  console.keyMap = "us";
  services.xserver.xkb = {
    layout = "us,ro";
    variant = ",std";
    options = "grp:alt_shift_toggle,caps:escape";
  };

  # ── Networking
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd"; # noticeably more reliable than wpa_supplicant on modern Intel/MTK/RTL cards
    # Let NetworkManager autoconnect from its saved (system-wide) profile.
    # With iwd doing it, the attempts at boot/login/resume were aborted and
    # wifi only came back after connecting by hand.
    settings.device."wifi.iwd.autoconnect" = false;
  };
  networking.firewall = {
    enable = true;
    # Nothing open by default. HTB/THM listeners go in modules/nixos/security.nix.
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # Resolve .local hostnames and find network printers.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # ── User account
  users.users.dawid = {
    isNormalUser = true;
    description = "dawid";
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "video"
      "audio"
      "input"
      "dialout" # serial devices / microcontrollers
      "libvirtd" # VMs (Kali etc.)
      "kvm"
      "docker"
      "wireshark" # packet capture without root
      "scanner"
      "lp" # printing
    ];
    shell = pkgs.zsh;
    # TODO(install): set a real password with `passwd dawid` right after the
    # first boot. Leaving this unset means you cannot log in at all.
    # initialPassword = "changeme";
  };
  programs.zsh.enable = true;

  # Keep sudo from re-prompting every 5 minutes during a long install session,
  # and log what was run.
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
    Defaults lecture=never
  '';

  # ── Firmware updates (`fwupdmgr refresh && fwupdmgr update`). Lenovo ships
  #    BIOS/EC updates through LVFS, so this genuinely works on a Legion.
  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  # ── Printing + scanning (you will need this for uni at some point)
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint hplip ];
  };
  hardware.sane.enable = true;

  # ── Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      # Lets modern headphones expose battery level.
      Experimental = true;
      # Better codec negotiation for AAC/aptX headsets.
      FastConnectable = true;
    };
  };

  # ── Shell-level niceties
  programs.command-not-found.enable = false; # replaced by nix-index below
  programs.nix-ld.enable = true; # see dev.nix for why this matters a lot here

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    rsync
    tree
    file
    unzip
    p7zip
    pciutils
    usbutils
    lm_sensors
    smartmontools
  ];
}
