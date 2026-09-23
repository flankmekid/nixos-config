# ── Neovim + LazyVim (hybrid model) ───────────────────────────────────────────
#
# Division of labour:
#   Nix        → the neovim binary, every LSP server, formatter, linter,
#                debugger and compiler. Reproducible, and they're on PATH so
#                other tools (VSCodium, the shell) use the same ones.
#   lazy.nvim  → the plugins themselves, installed to ~/.local/share/nvim at
#                runtime. `:Lazy` works exactly as upstream LazyVim expects.
#
# Consequence: plugin versions are pinned by ~/.config/nvim/lazy-lock.json,
# which is NOT in this repo by default. To make your plugin set reproducible
# too, copy that file into this directory after a `:Lazy sync` and it will be
# deployed on the next rebuild (see the commented line at the bottom).
#
# Mason is disabled on purpose — it downloads generic Linux binaries that do
# not run on NixOS. Everything it would have installed is in `home.packages`.
{ config, pkgs, lib, ... }:
{
  # Deployed with `recursive = true` so home-manager symlinks each FILE and
  # creates real directories. That matters: lazy.nvim needs to write
  # lazy-lock.json into ~/.config/nvim/, which it cannot do if the whole
  # directory is one read-only store symlink.
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  home.packages = with pkgs; [
    neovim

    # ── Runtime deps LazyVim assumes exist
    git
    gcc # nvim-treesitter compiles parsers with it
    gnumake
    unzip
    curl
    ripgrep # telescope/snacks live grep
    fd # telescope file finder
    fzf
    tree-sitter
    nodejs # a handful of plugins shell out to it
    lua51Packages.luarocks

    # ── Lua (for editing this config)
    lua-language-server
    stylua

    # ── Nix
    nixd
    nixfmt
    statix # linter LazyVim's nix extra runs through nvim-lint

    # ── C / C++
    clang-tools # clangd + clang-format
    lldb # nvim-dap backend
    cpplint

    # ── Java
    jdt-language-server
    google-java-format

    # ── C# / .NET
    omnisharp-roslyn
    netcoredbg

    # ── Python
    basedpyright
    ruff
    python3Packages.debugpy

    # ── SQL
    sqlfluff

    # ── LaTeX
    texlab
    tectonic

    # ── Web / config formats
    vscode-langservers-extracted # jsonls, html, cssls, eslint
    yaml-language-server
    taplo
    marksman
    markdownlint-cli2
    prettier

    # ── Shell
    bash-language-server
    shellcheck
    shfmt
  ];

  # Uncomment once you have a lazy-lock.json you're happy with, to pin plugins:
  # xdg.configFile."nvim/lazy-lock.json".source = ./nvim-lazy-lock.json;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
  };

  home.shellAliases = {
    vim = "nvim";
    vi = "nvim";
  };
}
