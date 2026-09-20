# ── Hyprland session, greeter, audio, portals, fonts ──────────────────────────
{ config, pkgs, lib, inputs, system, ... }:
{
  # ── Hyprland (the compositor). Caelestia is the SHELL on top of it and is
  #    configured per-user in home/.
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    withUWSM = true; # universal wayland session manager
  };

  # Portals: screen sharing (Teams/Zoom/Discord), file pickers, etc.
  # The Hyprland portal handles screencast; gtk handles file dialogs.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "hyprland" "gtk" ];
  };

  # ── Greeter. Without one you land on a bare TTY. tuigreet is lightweight and
  #    launches the uwsm-managed Hyprland session properly.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = lib.concatStringsSep " " [
        "${pkgs.greetd.tuigreet}/bin/tuigreet"
        "--time"
        "--remember"
        "--remember-user-session"
        "--asterisks"
        "--greeting 'legion'"
        "--cmd 'uwsm start hyprland-uwsm.desktop'"
      ];
      user = "greeter";
    };
  };
  # Stop boot logs from scribbling over the greeter.
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # ── Audio: PipeWire
  security.rtkit.enable = true;
  services.pulseaudio.enable = false; # PipeWire replaces it; both = no sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # ── Polkit: needed for GUI privilege prompts (mounting, virt-manager, etc.)
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true; # stores wifi/app secrets
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Unlock the keyring/session properly when you log in via greetd.
  security.pam.services.hyprlock = { };

  # ── Removable media: auto-mount USB sticks without root.
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  programs.file-roller.enable = true;

  # ── Fonts. Caelestia wants a Nerd Font + Material symbols; the rest is so
  #    that PDFs, .docx coursework and Romanian diacritics all render right.
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      material-symbols
      inter # UI font
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf # metric-compatible Arial/Times/Courier — matters for .docx
      corefonts # actual MS fonts, for documents that demand them
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Inter" "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
      # Crisper text on the laptop panel.
      antialias = true;
      hinting = { enable = true; style = "slight"; };
      subpixel.rgba = "rgb";
    };
  };

  # Dark theme by default across GTK/Qt (Caelestia is a dark shell).
  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "gtk2";
  };
}
