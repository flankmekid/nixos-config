-- Extra keymaps on top of LazyVim's defaults.
local map = vim.keymap.set

-- Save with Ctrl+S from any mode.
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Keep the cursor centred when jumping half-pages or through search results.
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move selected lines up/down, re-indenting as they go.
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Paste over a selection without clobbering the unnamed register.
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Delete to the black hole register.
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Yank to the system clipboard explicitly.
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })

-- Make the file under the cursor executable — constant need during CTF work.
map("n", "<leader>cx", "<cmd>!chmod +x %<CR>", { silent = true, desc = "chmod +x this file" })

-- Search-and-replace the word under the cursor across the file.
map("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word under cursor" })

-- Toggle spell checking (LaTeX/Markdown coursework).
map("n", "<leader>us", "<cmd>setlocal spell!<cr>", { desc = "Toggle spell check" })
