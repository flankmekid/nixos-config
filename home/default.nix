# ── Home Manager: per-user config for dawid ───────────────────────────────────
{ config, pkgs, lib, inputs, system, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta # or .twilight for the alpha channel
    inputs.caelestia.homeManagerModules.default # NOTE: homeManagerModules, not homeModules
    inputs.nix-index-database.homeModules.nix-index # prebuilt command-not-found database
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

  # The module links shell.json into the read-only Nix store, so the shell's
  # settings UI fails with "failed to save config". Instead, write a real file
  # and merge the Nix settings into it on each switch: the keys set in
  # programs.caelestia.settings win, and the UI can change everything else.
  xdg.configFile."caelestia/shell.json".enable = false;
  home.activation.caelestiaShellConfig =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      cfg="${config.xdg.configHome}/caelestia/shell.json"
      nixCfg="${config.xdg.configFile."caelestia/shell.json".source}"
      run mkdir -p "$(dirname "$cfg")"
      # Replace the old store symlink, or an unreadable file, with an empty object.
      if [ -L "$cfg" ] || ! ${pkgs.jq}/bin/jq -e . "$cfg" >/dev/null 2>&1; then
        run rm -f "$cfg"
        run sh -c "echo '{}' > \"$cfg\""
      fi
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$cfg" "$nixCfg" > "$tmp"
      run install -m 644 "$tmp" "$cfg"
      rm -f "$tmp"
    '';

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
      # No userSettings here: that would symlink settings.json into the
      # read-only store. The activation script below copies it instead.
    };
  };

  # Writable VSCodium settings.json. Each rebuild resets it to these values,
  # so settings changed in the UI only last until the next switch.
  home.activation.vscodiumSettings =
    let
      settings = pkgs.writeText "vscodium-settings.json" (builtins.toJSON {
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
      });
      target = "${config.xdg.configHome}/VSCodium/User/settings.json";
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run mkdir -p "$(dirname ${target})"
      run rm -f ${target} # drop the old store symlink or last copy
      run install -m 644 ${settings} ${target}
    '';

  # XDG user dirs — keeps ~/ from becoming a dumping ground.
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Dark GTK base theme. Caelestia themes GTK apps on top of it: it writes
  # ~/.config/gtk-{3,4}.0/gtk.css (and thunar.css for Thunar) in the current
  # scheme colours and updates them when the scheme changes.
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

  # Default apps. Home Manager now owns ~/.config/mimeapps.list; the Zen
  # module adds the browser entries itself.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      # Double-click .exe / .msi in Thunar to run them with Wine.
      "application/x-ms-dos-executable" = "wine.desktop";
      "application/x-msdownload" = "wine.desktop";
      "application/vnd.microsoft.portable-executable" = "wine.desktop";
      "application/x-msi" = "wine.desktop";
    };
  };
  xdg.desktopEntries.wine = {
    name = "Wine Windows Program Loader";
    exec = "wine start /unix %f";
    icon = "wine";
    terminal = false;
    noDisplay = true;
    mimeType = [
      "application/x-ms-dos-executable"
      "application/x-msdownload"
      "application/vnd.microsoft.portable-executable"
      "application/x-msi"
    ];
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
