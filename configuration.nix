{ config, pkgs, lib, inputs, system, ... }:

let
  # Spicetify's package set (themes/extensions) for this system.
  spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
in
{
  imports = [
    # Generated on the NEW laptop by `nixos-generate-config`. Contains disk
    # layout, kernel modules, etc. It won't exist until you run the installer —
    # comment this line out only if you're just evaluating the flake.
    ./hardware-configuration.nix
  ];

  # ── Boot (UEFI, systemd-boot — simpler than GRUB; gives you the generation menu)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking
  networking.hostName = "laptop";
  networking.networkmanager.enable = true;

  # ── Locale / time (adjust to yours)
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Unfree bits (Spotify, Steam, Zen, …)
  nixpkgs.config.allowUnfree = true;

  # ── Flakes need this experimental-features flag enabled.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── User account
  users.users.dawid = {
    isNormalUser = true;
    description = "dawid";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # ── Audio: PipeWire (same stack you run now)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Hyprland (the compositor). Caelestia is the SHELL that runs on top of it,
  #    configured per-user in the home-manager block below.
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    withUWSM = true; # session manager (you already use uwsm on the current box)
  };

  # ── Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfer.openFirewall = true;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # required for Steam / 32-bit games
  };

  # ── Spotify + Spicetify. This module installs Spotify for you —
  #    do NOT also add pkgs.spotify anywhere or they'll conflict.
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      shuffle
    ];
  };

  # ── System-wide packages
  environment.systemPackages = with pkgs; [
    vesktop # Discord client. Swap for `discord` below if you want the official one.
    # discord

    git
    kitty # a terminal (Caelestia expects one; change to taste)
    wl-clipboard
    brightnessctl
  ];

  # ── Fonts Caelestia expects (a Nerd Font + Material symbols)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    material-symbols
  ];

  # ── Home Manager: per-user config. Zen + Caelestia are home-manager modules.
  home-manager.users.dawid = { pkgs, ... }: {
    home.stateVersion = "26.05"; # keep in sync with system.stateVersion below

    imports = [
      inputs.zen-browser.homeModules.beta # or .twilight for the alpha channel
      inputs.caelestia.homeModules.default
    ];

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };

    programs.caelestia = {
      enable = true;
      cli.enable = true;
      systemd.enable = true; # run the shell as a user service on login
      # settings = { ... };  # mirrors Caelestia's shell.json — fill in later
    };
  };

  # Set at first install and then LEAVE IT — it is not "the version to upgrade to",
  # it pins state-format defaults so upgrades don't silently migrate your data.
  system.stateVersion = "26.05";
}
