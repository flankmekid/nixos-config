-- ── lazy.nvim bootstrap ──────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim core
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- ── Languages (matched to your ASE coursework) ──────────────────────────
    { import = "lazyvim.plugins.extras.lang.clangd" },   -- C / C++
    { import = "lazyvim.plugins.extras.lang.cmake" },
    { import = "lazyvim.plugins.extras.lang.java" },
    { import = "lazyvim.plugins.extras.lang.omnisharp" },-- C# / .NET
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.sql" },
    { import = "lazyvim.plugins.extras.lang.tex" },
    { import = "lazyvim.plugins.extras.lang.nix" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.git" },

    -- ── Editor ──────────────────────────────────────────────────────────────
    { import = "lazyvim.plugins.extras.editor.telescope" },
    { import = "lazyvim.plugins.extras.editor.harpoon2" },   -- jump between 4 files instantly
    { import = "lazyvim.plugins.extras.editor.refactoring" },
    { import = "lazyvim.plugins.extras.editor.inc-rename" },
    { import = "lazyvim.plugins.extras.editor.illuminate" },
    { import = "lazyvim.plugins.extras.editor.dial" },       -- <C-a>/<C-x> on dates, bools, hex
    { import = "lazyvim.plugins.extras.editor.mini-diff" },

    -- ── Coding ──────────────────────────────────────────────────────────────
    { import = "lazyvim.plugins.extras.coding.mini-surround" },
    { import = "lazyvim.plugins.extras.coding.yanky" },      -- yank ring
    { import = "lazyvim.plugins.extras.coding.luasnip" },

    -- ── Debugging + testing ─────────────────────────────────────────────────
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },

    -- ── UI ──────────────────────────────────────────────────────────────────
    { import = "lazyvim.plugins.extras.ui.treesitter-context" },
    { import = "lazyvim.plugins.extras.ui.mini-indentscope" },

    -- ── Utility ─────────────────────────────────────────────────────────────
    { import = "lazyvim.plugins.extras.util.project" },
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
    { import = "lazyvim.plugins.extras.util.dot" },          -- ssh config, gitconfig, etc.
    { import = "lazyvim.plugins.extras.formatting.prettier" },

    -- ── Your own overrides, in lua/plugins/ ─────────────────────────────────
    { import = "plugins" },
  },

  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },

  install = { colorscheme = { "catppuccin", "habamax" } },

  -- Check for plugin updates in the background, but don't nag.
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },

  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },

  ui = { border = "rounded" },
})
