vim.o.winborder = "rounded"
vim.o.number = true                              -- Line numbers
vim.o.ignorecase = true                                      -- Ignore case
vim.o.relativenumber = true                      -- Relative line numbers
vim.o.cursorline = true                          -- Highlight current line
vim.o.wrap = false                               -- Don't wrap lines
vim.o.scrolloff = 10                             -- Keep 10 lines above/below cursor
vim.o.sidescrolloff = 8                          -- Keep 8 columns left/right of cursor
vim.o.tabstop = 2                                -- Tab width
vim.o.termguicolors = true                       -- Enable 24-bit colors
vim.o.signcolumn = "yes"                         -- Always show sign column
vim.o.showmatch = true                           -- Highlight matching brackets
vim.o.swapfile = false                           -- Don't create swap files
vim.o.undofile = true                            -- Persistent undo
vim.g.mapleader = " "                            -- Set leader key to space
vim.cmd("set completeopt+=noselect")
vim.o.undodir = vim.fn.expand("~/.vim/undodir")  -- Undo directory
-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.pack.add({
        { src = "https://github.com/vague2k/vague.nvim" }
})
vim.cmd("colorscheme vague")
