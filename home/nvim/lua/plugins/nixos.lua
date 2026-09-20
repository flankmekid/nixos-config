-- ── NixOS adaptations ────────────────────────────────────────────────────────
-- Mason downloads prebuilt, dynamically-linked binaries from the internet.
-- Those do not run on NixOS (no /lib64/ld-linux-x86-64.so.2), so mason is
-- disabled and every server/formatter/linter comes from Nix instead — see
-- home/neovim.nix. lspconfig still starts anything it finds on PATH.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "williamboman/mason.nvim", enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },

  -- Treesitter parsers still compile locally (gcc is provided by Nix), which
  -- works fine. Pre-install the ones you will actually use so the first open
  -- of a file is not a compile pause.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c", "cpp", "java", "c_sharp", "python", "sql", "latex", "bibtex",
        "nix", "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline", "dockerfile", "regex", "diff", "r",
      },
    },
  },
}
