# ── Home Manager: per-user config for dawid ───────────────────────────────────
{ config, pkgs, lib, inputs, system, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta # or .twilight for the alpha channel
    inputs.caelestia.homeManagerModules.default # NOTE: homeManagerModules, not homeModules
    ./shell.nix
    ./terminal.nix
    ./clipboard.nix
    ./neovim.nix
    ./hyprland.nix
    ./caelestia-hypr.nix
    ./git.nix
  ];

  home.username = "dawid";
  home.homeDirectory = "/home/dawid";
  home.stateVersion = "26.05"; # keep in sync with system.stateVersion

  programs.home-manager.enable = true;

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
  };

  programs.caelestia = {
    enable = true;
    # Use the brightnessctl wrapper from modules/nixos/nvidia.nix, which
    # targets the real panel backlight (amdgpu_bl1) instead of nvidia_0.
    package = inputs.caelestia.packages.${system}.with-cli.override {
      inherit (pkgs) brightnessctl;
    };
    cli.enable = true;
    # Apps the special workspace keys start, or pull back in if they were
    # moved out. The defaults point at apps that are not installed here.
    cli.settings.toggles = {
      # SUPER + D
      communication = {
        discord.enable = false;
        vesktop = {
          enable = true;
          match = [ { class = "vesktop"; } ];
          command = [ "vesktop" ];
          move = true;
        };
      };
      # SUPER + M. spicetify-nix already applies the theme to this Spotify.
      music.spotify.command = [ "spotify" ];
      # CTRL + SHIFT + Escape
      sysmon.btop.command = [ "kitty" "--class" "btop" "--title" "btop" "btop" ];
      # SUPER + R
      todo.todoist.enable = false;
    };
    systemd.enable = true; # run the shell as a user service on login
    # Mirrors Caelestia's shell.json. Full option list:
    #   https://github.com/caelestia-dots/shell
    settings = {
      general.apps.terminal = [ "kitty" ];

      # Idle handling (replaces hypridle + hyprlock, which stacked a second
      # lock screen on top of Caelestia's). Timeouts are in seconds.
      # String actions other than "lock"/"dpms off"/"dpms on" are sent to
      # Hyprland as dispatches, so shell commands must be lists.
      general.idle = {
        lockBeforeSleep = true;
        inhibitWhenAudio = true; # no dimming/locking while media plays
        inhibitWhenCharging = false; # per-timeout below instead
        timeouts = [
          # Dim first so you get a chance to move the mouse.
          {
            timeout = 240;
            idleAction = [ "brightnessctl" "-s" "set" "10%" ];
            returnAction = [ "brightnessctl" "-r" ];
          }
          { timeout = 300; idleAction = "lock"; }
          { timeout = 420; idleAction = "dpms off"; returnAction = "dpms on"; }
          # Suspend after 30 min, but only on battery — on AC, let long
          # builds, scans and hashcat runs finish unattended.
          {
            timeout = 1800;
            idleAction = [ "systemctl" "suspend" ];
            inhibitWhenCharging = true;
          }
        ];
      };
    };
  };

  home.packages = with pkgs; [
    hyprmod # GUI for Hyprland settings; writes ~/.config/hypr/hyprland-gui.lua
    pwvucontrol # Caelestia's audio settings app (CTRL + ALT + V)
  ];

  # VSCodium — extensions declared here so the setup is reproducible.
  # LSPs/compilers come from modules/nixos/dev.nix and are found on PATH.
  programs.vscodium = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Languages
        ms-dotnettools.csharp
        redhat.java
        vscjava.vscode-java-debug
        ms-python.python
        ms-python.debugpy
        charliermarsh.ruff
        llvm-vs-code-extensions.vscode-clangd
        james-yu.latex-workshop
        jnoortheen.nix-ide
        # Tooling
        eamodio.gitlens
        mkhl.direnv
        usernamehw.errorlens
        esbenp.prettier-vscode
        catppuccin.catppuccin-vsc
        vscodevim.vim # muscle memory stays consistent with Neovim
      ];
      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "workbench.colorTheme" = "Catppuccin Mocha";
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none"; # Nix owns the version
        "extensions.autoUpdate" = false;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "terminal.integrated.defaultProfile.linux" = "zsh";
      };
    };
  };

  # XDG user dirs — keeps ~/ from becoming a dumping ground.
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Dark theme for GTK apps so they match Caelestia.
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Scratch directories you will use constantly.
  home.file."ctf/.keep".text = "";
  home.file."uni/.keep".text = "";
  home.file."vpn/.keep".text = "";
}
