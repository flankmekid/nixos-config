-- ── Extra plugins beyond LazyVim's defaults ──────────────────────────────────
return {
  -- Seamless navigation between Neovim splits and tmux panes with <C-hjkl>.
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window" },
    },
  },

  -- Query databases from inside Neovim. Pairs with the Postgres service in
  -- modules/nixos/dev.nix. <leader>D to open.
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = { { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" } },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
    end,
  },

  -- An HTTP client in a buffer. Faster than alt-tabbing to Postman when you
  -- are poking at a web target or a coursework API.
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    opts = {},
  },

  -- Jupyter-style cell execution, for the stats/econometrics work.
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    cmd = { "MoltenInit", "MoltenEvaluateOperator", "MoltenEvaluateLine" },
    init = function()
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
    end,
  },

  -- Undo history as a tree. Saves you more than once a semester.
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" } },
  },

  -- Hex editor, for CTF binary and forensics work.
  {
    "RaafatTurki/hex.nvim",
    cmd = { "HexToggle", "HexDump", "HexAssemble" },
    opts = {},
  },

  -- Render Markdown nicely in the buffer (notes, writeups).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {},
  },
}
