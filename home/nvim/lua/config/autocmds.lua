-- Extra autocommands on top of LazyVim's defaults.
local augroup = vim.api.nvim_create_augroup("dawid", { clear = true })

-- Spell + wrap for prose filetypes.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "tex", "plaintex", "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- 2-space indent where the ecosystem expects it.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "lua", "nix", "json", "jsonc", "yaml", "html", "css", "javascript", "typescript" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Real tabs in C/C++, matching ~/.clang-format (see home/neovim.nix).
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Treat common CTF/tooling files as the right filetype.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { "*.nmap", "*.gnmap" },
  callback = function() vim.bo.filetype = "text" end,
})
