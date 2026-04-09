-- import the options.lua file
require("options")

-- import file with all the lazy configs
require("plugins")

-- treesitter configs
require("tsconfig")

-- set color of word highlight to magenta
vim.cmd([[hi MatchParen cterm=bold ctermfg=magenta guifg=magenta]])

-- LSPs
require("mason").setup()
