# ── zsh, prompt, and CLI ergonomics ───────────────────────────────────────────
{ config, pkgs, lib, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin" # `cargo install` puts binaries here
  ];
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true; # prefix a command with a space to keep it out of history
      share = true;
      extended = true;
    };

    shellAliases = {
      # ── NixOS workflow
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config#laptop";
      rebuild-boot = "sudo nixos-rebuild boot --flake ~/nixos-config#laptop";
      # Dry-run: see what WOULD change without touching the running system.
      rebuild-dry = "nixos-rebuild dry-build --flake ~/nixos-config#laptop";
      update = "nix flake update --flake ~/nixos-config";
      # Roll back to the previous generation if a rebuild broke something.
      rollback = "sudo nixos-rebuild switch --rollback";
      generations = "nix profile history --profile /nix/var/nix/profiles/system";
      gc = "sudo nix-collect-garbage --delete-older-than 14d && nix-collect-garbage -d";
      search = "nix search nixpkgs";

      # ── Everyday
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first --git";
      la = "eza -la --icons --group-directories-first --git";
      lt = "eza --tree --level=2 --icons";
      cat = "bat";
      grep = "rg";
      du = "dust";
      df = "duf";
      top = "btop";
      v = "nvim";
      lg = "lazygit";
      ports = "ss -tulpn";

      # ── Security lab
      # Serve the current directory to a target box (classic privesc step).
      serve = "python3 -m http.server 8000";
      # Your VPN IP, which every walkthrough asks you to substitute in.
      tunip = "ip -4 addr show tun0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'";
      listen = "nc -lvnp 4444";
      # hashcat on the RTX 5060 rather than the CPU.
      hashcat = "nvidia-offload hashcat";
    };

    initContent = ''
      # Caelestia's current colour scheme (from the wallpaper) for new kitty
      # windows. Caelestia recolours already-open terminals itself when the
      # scheme changes. The prompt keeps its own fixed colours.
      if [[ $TERM == xterm-kitty && -r ~/.local/state/caelestia/sequences.txt ]]; then
        command cat ~/.local/state/caelestia/sequences.txt
      fi

      # Use the dGPU for a one-off command:  gpu blender
      gpu() { nvidia-offload "$@"; }

      # mkcd — make a directory and enter it
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # install <pkg>...    add to modules/nixos/packages.txt, rebuild, commit
      # uninstall <pkg>...  remove from it, rebuild, commit
      # A failed rebuild puts the list back. `install -m 755 a b` and other
      # flag forms still run coreutils install.
      _pkgs_cfg=~/nixos-config
      _pkgs_list=~/nixos-config/modules/nixos/packages.txt
      install() {
        if (( $# == 0 )) || [[ $1 == -* ]]; then command install "$@"; return; fi
        local p; local -a added
        for p in "$@"; do
          if command grep -qxF -- "$p" $_pkgs_list; then
            echo "$p is already in packages.txt"; continue
          fi
          if ! nix eval --raw --inputs-from $_pkgs_cfg "nixpkgs#$p.name" >/dev/null 2>&1; then
            echo "No package called '$p'. Try: search $p"; return 1
          fi
          echo "$p" >> $_pkgs_list; added+=("$p")
        done
        (( $#added )) || return 0
        if sudo nixos-rebuild switch --flake $_pkgs_cfg#laptop; then
          git -C $_pkgs_cfg commit -q -m "Install $added" -- $_pkgs_list
          echo "Installed: $added"
        else
          command grep -vxF -f <(print -l -- $added) $_pkgs_list > $_pkgs_list.tmp
          mv $_pkgs_list.tmp $_pkgs_list
          echo "Rebuild failed; took $added back out of packages.txt."; return 1
        fi
      }
      uninstall() {
        if (( $# == 0 )); then echo "usage: uninstall <package>..."; return 1; fi
        local p; local -a removed
        for p in "$@"; do
          if command grep -qxF -- "$p" $_pkgs_list; then
            removed+=("$p")
          else
            echo "$p is not in packages.txt (only packages added with install are)."
            command grep -rlw --include='*.nix' -- "$p" $_pkgs_cfg/modules $_pkgs_cfg/home \
              | sed "s|^$_pkgs_cfg/|  It is listed in: |"
          fi
        done
        (( $#removed )) || return 1
        command grep -vxF -f <(print -l -- $removed) $_pkgs_list > $_pkgs_list.tmp
        mv $_pkgs_list.tmp $_pkgs_list
        if sudo nixos-rebuild switch --flake $_pkgs_cfg#laptop; then
          git -C $_pkgs_cfg commit -q -m "Uninstall $removed" -- $_pkgs_list
          echo "Uninstalled: $removed"
        else
          print -l -- $removed >> $_pkgs_list
          echo "Rebuild failed; put $removed back in packages.txt."; return 1
        fi
      }

      # Spin up a scratch dir for an HTB/THM box:  box nibbles
      box() {
        local d=~/ctf/"$1"
        mkdir -p "$d"/{nmap,loot,exploits,www}
        cd "$d"
      }

      # Ctrl+arrow word jumps, Home/End, Alt+Backspace deletes a word.
      # zsh switches to vi insert mode after this file runs (EDITOR is nvim),
      # so plain `bindkey` would only set the unused emacs keymap.
      for km in emacs viins; do
        bindkey -M $km "^[[1;5C" forward-word
        bindkey -M $km "^[[1;5D" backward-word
        bindkey -M $km "^[[H" beginning-of-line
        bindkey -M $km "^[[F" end-of-line
        bindkey -M $km "^[^?" backward-kill-word
      done

      # System info with the NixOS logo in each new kitty window (not in
      # nested shells or editor terminals). The logo is 72 columns wide with
      # the text, so narrower windows get the text only and nothing wraps.
      if [[ $TERM == xterm-kitty && $SHLVL -le 1 && -z $NVIM ]]; then
        if (( COLUMNS >= 74 )); then
          fastfetch
        else
          fastfetch --logo none
        fi
      fi
    '';
  };

  # Prompt: powerline segments (OS, user, directory, git, language versions,
  # command duration, time), then ❯ on its own line. Catppuccin Mocha, cool
  # tones only; change the hex values in the palette at the bottom.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      palette = "catppuccin_cool";

      format = lib.concatStrings [
        "[](user)"
        "$os"
        "$username"
        "[](bg:dir fg:user)"
        "$directory"
        "[](bg:git fg:dir)"
        "$git_branch"
        "$git_status"
        "[](fg:git bg:lang)"
        "$c"
        "$cpp"
        "$rust"
        "$python"
        "$java"
        "$nodejs"
        "$nix_shell"
        "[](fg:lang bg:duration)"
        "$cmd_duration"
        "[](fg:duration bg:time)"
        "$time"
        "[ ](fg:time)"
        "$line_break"
        "$character"
      ];

      os = {
        disabled = false;
        style = "bg:user fg:ink";
        symbols.NixOS = "";
      };
      username = {
        show_always = true;
        style_user = "bg:user fg:ink";
        style_root = "bg:user fg:ink";
        format = "[ $user ]($style)";
      };
      directory = {
        style = "bg:dir fg:ink";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "nixos-config" = " nixos-config";
        };
      };
      git_branch = {
        symbol = "";
        style = "bg:git";
        format = "[[ $symbol $branch ](fg:ink bg:git)]($style)";
      };
      git_status = {
        style = "bg:git";
        format = "[[($all_status$ahead_behind )](fg:ink bg:git)]($style)";
      };
      c = {
        symbol = " ";
        format = "[[ $symbol( $version) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      cpp = {
        symbol = " ";
        format = "[[ $symbol( $version) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      rust = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      python = {
        symbol = "";
        format = "[[ $symbol( $version)( \\($virtualenv\\)) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      java = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      nodejs = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      nix_shell = {
        symbol = "";
        format = "[[ $symbol( $name) ](fg:ink bg:lang)]($style)";
        style = "bg:lang";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bg:duration";
        format = "[[  $duration ](fg:ink bg:duration)]($style)";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:time";
        format = "[[  $time ](fg:ink bg:time)]($style)";
      };
      line_break.disabled = false;
      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:user)";
        error_symbol = "[❯](bold fg:error)";
        vimcmd_symbol = "[❮](bold fg:user)";
      };

      # One colour per prompt block; the names are used in the format above.
      palettes.catppuccin_cool = {
        user = "#cba6f7"; # OS + user: mauve
        dir = "#f5c2e7"; # directory: pink
        git = "#b4befe"; # git: lavender
        lang = "#89b4fa"; # languages: blue
        duration = "#74c7ec"; # command duration: sapphire
        time = "#cba6f7"; # time: mauve
        ink = "#11111b"; # text on the segments
        error = "#f38ba8"; # ❯ after a failed command: red
      };
    };
  };

  # Directory jumping: `z nixos` instead of a long cd.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  programs.bat = {
    enable = true;
    config.theme = "Catppuccin-mocha";
  };

  programs.btop.enable = true;
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10; # stops the ESC lag in Neovim inside tmux
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
  };

  # `nix-locate libssl.so` — tells you which package provides a missing file.
  # Invaluable when a prebuilt binary complains about a library.
  # The database comes prebuilt from the nix-index-database flake input.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  # `, <program>` runs any program once without installing it: , cowsay hi
  programs.nix-index-database.comma.enable = true;

  # Fetch shown in each new terminal (see initContent). Same fields as the
  # old microfetch output.
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = ./nixos-logo.txt; # microfetch's braille logo
        color = {
          "1" = "blue";
          "2" = "cyan";
        };
        padding.right = 2;
      };
      display = {
        separator = " │ "; # keys below are padded so this lines up
        color = {
          keys = "blue";
          output = "default";
        };
        percent.type = 9; # coloured number, no bar
      };
      modules = [
        {
          type = "title";
          color = {
            user = "yellow";
            at = "red";
            host = "green";
          };
        }
        { type = "os"; key = "{#cyan}  {#blue}System     "; format = "{name} {version-id} ({codename})"; }
        { type = "kernel"; key = "{#cyan}  {#blue}Kernel     "; }
        { type = "cpu"; key = "{#cyan}  {#blue}CPU        "; format = "{name}"; }
        { type = "cpu"; key = "{#cyan}  {#blue}Topology   "; format = "{cores-physical} cores, {cores-logical} threads"; }
        { type = "shell"; key = "{#cyan}  {#blue}Shell      "; format = "{pretty-name}"; }
        { type = "uptime"; key = "{#cyan}󰅐  {#blue}Uptime     "; }
        { type = "wm"; key = "{#cyan}󰍹  {#blue}Desktop    "; format = "{pretty-name} (Wayland)"; }
        { type = "memory"; key = "{#cyan}󰍛  {#blue}Memory     "; }
        { type = "disk"; key = "{#cyan}󱥎  {#blue}Storage (/)"; folders = "/"; format = "{size-used} / {size-total} ({size-percentage})"; }
        { type = "colors"; key = "{#cyan}󰏘  {#blue}Colors     "; symbol = "circle"; }
      ];
    };
  };

  home.packages = with pkgs; [
    eza
    fd
    ripgrep
    dust
    duf
    sd # friendlier sed
    hyperfine
    tldr
    jq
  ];
}
