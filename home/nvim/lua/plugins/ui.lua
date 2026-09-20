-- ── Look and feel ────────────────────────────────────────────────────────────
return {
  -- Catppuccin Mocha, matching Spicetify, kitty and VSCodium.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        telescope = true,
        which_key = true,
        treesitter_context = true,
        mini = true,
        harpoon = true,
        dap = true,
        dap_ui = true,
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },

  -- Show the file's path in the statusline, not just its name — useful when
  -- you have eight similarly-named lab files open.
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_c, { "filename", path = 1 })
      return opts
    end,
  },
}
