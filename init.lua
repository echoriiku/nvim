vim.cmd.colorscheme("sorbet")
vim.o.winborder = "rounded"
vim.opt.number = true                              -- Line numbers
vim.opt.relativenumber = true                      -- Relative line numbers
vim.opt.cursorline = true                          -- Highlight current line
vim.opt.wrap = false                               -- Don't wrap lines
vim.opt.scrolloff = 10                             -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8                          -- Keep 8 columns left/right of cursor
vim.opt.tabstop = 4                                -- Tab width
vim.opt.termguicolors = true                       -- Enable 24-bit colors
vim.opt.signcolumn = "yes"                         -- Always show sign column
vim.opt.showmatch = true                           -- Highlight matching brackets
vim.opt.matchtime = 2                              -- How long to show matching bracket
vim.opt.swapfile = false                           -- Don't create swap files
vim.opt.undofile = true                            -- Persistent undo
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")  -- Undo directory
vim.g.mapleader = " "                              -- Set leader key to space
-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
