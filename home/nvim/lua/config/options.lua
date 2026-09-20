-- Loaded by LazyVim before plugins. LazyVim's own defaults are already good;
-- this is only the deltas.
local opt = vim.opt

opt.relativenumber = true
opt.number = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- 4-space indent is what the C/Java/C# coursework graders expect.
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.undofile = true
opt.undolevels = 10000
opt.confirm = true       -- prompt instead of failing when quitting unsaved buffers
opt.splitkeep = "screen"
opt.cursorline = true
opt.colorcolumn = "100"

-- Persist the clipboard to the Wayland selection via wl-clipboard.
opt.clipboard = "unnamedplus"

-- Spell-check prose (LaTeX, Markdown) in English and Romanian.
opt.spelllang = { "en_us", "ro" }

-- Faster CursorHold-driven diagnostics/highlights.
opt.updatetime = 200
opt.timeoutlen = 300

-- LazyVim reads these for its own defaults.
vim.g.lazyvim_picker = "telescope"
vim.g.lazyvim_cmp = "blink.cmp"
vim.g.autoformat = true

-- Python provider: use the Nix-provided interpreter rather than hunting PATH.
vim.g.python3_host_prog = vim.fn.exepath("python3")
