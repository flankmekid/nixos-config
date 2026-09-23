# ── zsh, prompt, and CLI ergonomics ───────────────────────────────────────────
{ config, pkgs, lib, ... }:
{
  home.sessionPath = [ "$HOME/.local/bin" ];
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

  # Prompt: Catppuccin Mocha powerline segments (OS, user, directory, git,
  # language versions, command duration, time), then ❯ on its own line.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      palette = "catppuccin_mocha";

      format = lib.concatStrings [
        "[](red)"
        "$os"
        "$username"
        "[](bg:peach fg:red)"
        "$directory"
        "[](bg:yellow fg:peach)"
        "$git_branch"
        "$git_status"
        "[](fg:yellow bg:green)"
        "$c"
        "$cpp"
        "$rust"
        "$python"
        "$java"
        "$nodejs"
        "$nix_shell"
        "[](fg:green bg:sapphire)"
        "$cmd_duration"
        "[](fg:sapphire bg:lavender)"
        "$time"
        "[ ](fg:lavender)"
        "$line_break"
        "$character"
      ];

      os = {
        disabled = false;
        style = "bg:red fg:crust";
        symbols.NixOS = "";
      };
      username = {
        show_always = true;
        style_user = "bg:red fg:crust";
        style_root = "bg:red fg:crust";
        format = "[ $user ]($style)";
      };
      directory = {
        style = "bg:peach fg:crust";
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
        style = "bg:yellow";
        format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
      };
      git_status = {
        style = "bg:yellow";
        format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
      };
      c = {
        symbol = " ";
        format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      cpp = {
        symbol = " ";
        format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      rust = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      python = {
        symbol = "";
        format = "[[ $symbol( $version)( \\($virtualenv\\)) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      java = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      nodejs = {
        symbol = "";
        format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      nix_shell = {
        symbol = "";
        format = "[[ $symbol( $name) ](fg:crust bg:green)]($style)";
        style = "bg:green";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bg:sapphire";
        format = "[[  $duration ](fg:crust bg:sapphire)]($style)";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:lavender";
        format = "[[  $time ](fg:crust bg:lavender)]($style)";
      };
      line_break.disabled = false;
      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:green)";
        error_symbol = "[❯](bold fg:red)";
        vimcmd_symbol = "[❮](bold fg:green)";
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
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
