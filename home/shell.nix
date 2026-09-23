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
      # Use the dGPU for a one-off command:  gpu blender
      gpu() { nvidia-offload "$@"; }

      # mkcd — make a directory and enter it
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # Spin up a scratch dir for an HTB/THM box:  box nibbles
      box() {
        local d=~/ctf/"$1"
        mkdir -p "$d"/{nmap,loot,exploits,www}
        cd "$d"
      }

      # Ctrl+arrow word jumps, Home/End, etc.
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line

      # System info with the NixOS logo in each new kitty window (not in
      # nested shells or editor terminals).
      if [[ $TERM == xterm-kitty && $SHLVL -le 1 && -z $NVIM ]]; then
        microfetch
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

  home.packages = with pkgs; [
    microfetch # NixOS-only fetch tool, runs in each new terminal (see initContent)
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
