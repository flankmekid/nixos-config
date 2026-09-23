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
    '';
  };

  # Fast, informative prompt.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      nix_shell.format = "[$symbol$name]($style) ";
      git_status.disabled = false;
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
