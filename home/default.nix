# ── Home Manager: per-user config for dawid ───────────────────────────────────
{ config, pkgs, lib, inputs, system, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta # or .twilight for the alpha channel
    inputs.caelestia.homeManagerModules.default # NOTE: homeManagerModules, not homeModules
    ./shell.nix
    ./terminal.nix
    ./neovim.nix
    ./hyprland.nix
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
    cli.enable = true;
    systemd.enable = true; # run the shell as a user service on login
    # Mirrors Caelestia's shell.json. Full option list:
    #   https://github.com/caelestia-dots/shell
    settings = {
      general.apps.terminal = [ "kitty" ];
      bar.status.showBattery = true;
      paths.wallpaperDir = "~/Pictures/wallpapers";
    };
  };

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
