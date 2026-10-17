# ── Everyday applications ─────────────────────────────────────────────────────
{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${system};
in
{
  # ── Spotify + Spicetify. This module installs Spotify itself —
  #    do NOT also add pkgs.spotify anywhere or they will conflict.
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      shuffle
      beautifulLyrics
    ];
  };

  # ydotool daemon: Caelestia's "paste latest clipboard entry" bind
  # (CTRL + SHIFT + ALT + V) types text with it. Needs the ydotool group.
  programs.ydotool.enable = true;
  users.users.dawid.extraGroups = [ config.programs.ydotool.group ];

  # Thunar is the default file manager (SUPER + E; defaults in home/default.nix).
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin # right-click extract / compress
      thunar-volman # auto-mount USB drives
      thunar-media-tags-plugin
    ];
  };
  programs.xfconf.enable = true; # Thunar saves its settings here
  services.tumbler.enable = true; # image and video thumbnails

  environment.systemPackages = with pkgs; [
    anki
    vesktop # Discord client with working Wayland screenshare
    # discord    # the official one, if you ever need voice-activity features

    qbittorrent

    # Files / media
    nautilus
    mpv
    ffmpeg # convert/cut/record audio and video
    imv # lightweight image viewer
    obs-studio # recording coursework demos / CTF writeups
    lmstudio

    # Terminal-adjacent utilities Caelestia and Hyprland expect
    kitty
    wl-clipboard
    cliphist # clipboard history
    brightnessctl
    playerctl
    grim
    slurp
    swappy # annotate screenshots — genuinely useful for writeups
    hyprpicker
    libnotify
    mpv
    ffmpeg

    # Notes / study
    obsidian
    anki
    # zotero # TEMP: 10.0.4 fails to build on current nixpkgs; re-enable later
    zathura
    qalculate-qt
    pavucontrol

    # terminal applications
    cava
    cmatrix
    cowsay
    qdirstat
    litecli # SQLite client with autocomplete + syntax highlighting

    # Comms for online classes. Teams' native Linux client is dead, so this is
    # the PWA wrapper; it works fine for calls and screen share via portals.
    teams-for-linux
    zoom-us
    thunderbird
  ];
}
