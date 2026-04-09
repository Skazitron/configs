-- disable line wrapping (line breaking into the next line)
vim.opt.wrap = false

-- enable line numbers --
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.splitbelow = true
vim.opt.splitright = true

-- expand a tab into 4 spaces --
vim.opt.expandtab = true
vim.opt.tabstop = 4

-- set clipboard to system clipboard --
vim.opt.clipboard = "unnamedplus"

-- keep cursor at the center of the screen --
vim.opt.scrolloff = 999

-- number of spaces to each step of (auto)indent --
vim.opt.shiftwidth = 4

-- set virtual edit to block --
vim.opt.virtualedit = "block"

vim.opt.inccommand = "split"

vim.opt.termguicolors = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.undofile = true

vim.keymap.set("n", "<leader><leader>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ==========================================
-- TREESITTER FOLDING
-- ==========================================

-- Tell Neovim to use Treesitter for folding
-- (If you are on Neovim 0.10+, you can use "v:lua.vim.treesitter.foldexpr()")
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- The magic settings to keep files unfolded when you first open them
vim.opt.foldlevelstart = 99
vim.opt.foldlevel = 99
vim.opt.foldenable = true

-- ==========================================
-- KEYMAPS
-- ==========================================

-- Normal mode: Toggle the fold under the cursor
vim.keymap.set('n', '<leader>f', 'za', { desc = 'Toggle fold' })

-- Note: We drop the visual mode 'zf' keymap here.
-- With Treesitter handling the logic, you just put your cursor inside
-- a block (like that handleLinkChange function) and hit <leader>f to toggle it.

-- ==========================================
-- PERSISTENT FOLDS
-- ==========================================

-- Save and restore the view (which includes fold states)
local view_group = vim.api.nvim_create_augroup("PersistentViews", { clear = true })

vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  group = view_group,
  pattern = "?*", -- The ?* prevents this from triggering on empty buffers
  command = "mkview",
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = view_group,
  pattern = "?*",
  command = "silent! loadview",
})

-- Automatically open Snacks Explorer on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local args = vim.fn.argv()
    if #args == 0 or vim.fn.isdirectory(args[1]) == 1 then
      -- Tell Snacks to open, but actively refuse focus
      require("snacks").explorer({ focus = false })
    end
  end,
})

-- Window navigation with Ctrl + hjkl
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Open the error popup and instantly move the cursor inside it
vim.keymap.set("n", "<leader>d", function()
  vim.diagnostic.open_float({ focus = true })
end, { desc = "Hover Diagnostics (Focused)" })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Close all --
vim.keymap.set("n", "<A-w>", "<cmd>qa<CR>", { desc = "Close all" })

vim.opt.fillchars:append({ eob = " " })

vim.opt.mousemoveevent = true
