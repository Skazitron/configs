-- the fn commands are to call vimscript commands
-- stdpath("data") finds location where vim stores its data
-- the .. appends the string to the data path
-- then it proceeds to clone the repo into it
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- this adds a directory to the run time path
-- for example, a directory for linting c++ code
-- might be added to the run time path
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- 1. Modern Utilities & Pickers
    {
      "ThePrimeagen/refactoring.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
      },
      lazy = false,
      opts = {},
      keys = {
        {
          "<leader>r",
          function() require('refactoring').select_refactor() end,
          mode = { "n", "x" },
          desc = "Open Refactor Menu",
        },
      },
    },
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        rename = { enabled = true },
        styles = {
          default = { backdrop = false },
          picker = {
            wo = { winhighlight = "NormalFloat:Normal,FloatBorder:Normal" }
          },
          explorer = {
            wo = { winhighlight = "NormalFloat:Normal,FloatBorder:Normal" }
          },
        },

        -- 2. YOUR EXISTING CONFIG REMAINS THE SAME
        bigfile = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = false },
        explorer = {
          enabled = true,
          replace_netrw = true,
        },
        statuscolumn = {
          -- your statuscolumn configuration comes here
        },
        picker = {
          enabled = true,
          sources = {
            explorer = {
              layout = {
                preset = "right",
                layout = {
                  width = 40,
                  min_width = 40
                }
              }
            }
          }
        },
        words = { enabled = true },
      },
      keys = {
        { "<leader><Tab>", function() Snacks.picker.smart() end,           desc = "Smart Find Files" },
        { "<leader>w",     function() Snacks.picker.grep_word() end,       desc = "Grep Word/Selection",   mode = { "n", "x" } },
        { "<leader>g",     function() Snacks.picker.grep() end,            desc = "Grep Workspace" },
        { "<leader>e",     function() Snacks.explorer() end,               desc = "File Explorer" },
        { "<leader>lg",    function() Snacks.lazygit() end,                desc = "Lazygit" },
        { "<leader>s",     function() Snacks.picker.lsp_references() end,  desc = "Search/Grep Project" },
        { "<leader>i",     function() Snacks.picker.lsp_definitions() end, desc = "Search LSP definitions" },
      },
    },

    -- 2. Formatting
    {
      "stevearc/conform.nvim",
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          rust = { "rustfmt" },
          go = { "goimports", "gofmt" },
          cpp = { "clang-format" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      },
    },

    -- 3. LSP & Mason
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        {
          "folke/lazydev.nvim",
          ft = "lua",
          opts = {
            library = {
              { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
          },
        },
      },
      config = function()
        -- 1. Initialize Mason
        require("mason").setup({
          ui = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        })

        -- 2. Define your languages
        local servers = { "lua_ls", "rust_analyzer", "gopls", "pyright", "clangd", "svelte", "vtsls", "tailwindcss" }

        -- 3. Tell Mason to install them (include eslint here so Mason still manages the binary)
        require("mason-lspconfig").setup({
          ensure_installed = vim.list_extend(vim.deepcopy(servers), { "eslint" })
        })

        -- 4. Get Autocompletion Capabilities (Safely)
        local has_blink, blink = pcall(require, "blink.cmp")
        local capabilities = vim.tbl_deep_extend(
          "force",
          {},
          vim.lsp.protocol.make_client_capabilities(),
          has_blink and blink.get_lsp_capabilities() or {},
          {
            workspace = {
              fileOperations = {
                willRename = true,
                didRename = true,
              },
            },
          }
        )

        -- 5. Wire up generic servers
        for _, server in ipairs(servers) do
          vim.lsp.config(server, {
            capabilities = capabilities
          })
          vim.lsp.enable(server)
        end

        -- 6. ESLint needs its own root_dir to avoid the "paths[0]" error
        vim.lsp.config("eslint", {
          capabilities = capabilities,
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local dir = vim.fs.dirname(fname)
            local match = vim.fs.find({
              "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
              ".eslintrc.js", ".eslintrc.json", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc",
              "package.json",
            }, { path = dir, upward = true })[1]
            on_dir(match and vim.fs.dirname(match) or vim.fn.getcwd())
          end,
        })
        vim.lsp.enable("eslint")
      end,
    },
    -- 4. Completion (Blink)
    {
      'saghen/blink.cmp',
      dependencies = { 'rafamadriz/friendly-snippets' },
      version = '1.*',
      opts = {
        keymap = { preset = 'super-tab' },
        appearance = {
          nerd_font_variant = 'mono'
        },
        completion = { documentation = { auto_show = true } },
        sources = {
          default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            }
          }
        },
        fuzzy = { implementation = "prefer_rust_with_warning" }
      },
      opts_extend = { "sources.default" }
    },

    -- 5. Treesitter Bundle
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        require('nvim-treesitter.configs').setup({
          ensure_installed = {
            'rust', 'javascript', 'typescript', 'tsx', 'zig', 'lua', 'go', 'gomod', 'gowork', 'gotmpl',
            'c', 'cpp', 'python', 'html', 'java', 'json', 'markdown', 'svelte',
            'yaml', 'css', 'bash', 'proto',
          },
          -- Satisfies the LuaLS TSConfig warnings
          sync_install = false,
          auto_install = true,
          ignore_install = {},
          modules = {},

          highlight = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = "<Enter>",
              node_incremental = "<Enter>",
              node_decremental = "<Backspace>",
            },
          },
          textobjects = {
            select = {
              lookahead = true,
              selection_modes = {
                ['@parameter.outer'] = 'v',
                ['@function.outer'] = 'V',
              },
            },
            move = { set_jumps = true }
          }
        })
      end,
      dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
    },
    { "tpope/vim-sleuth" },
    -- 7. Themes
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

    {
      "yazeed1s/oh-lucy.nvim",
      name = "oh-lucy",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("oh-lucy-evening")
        vim.api.nvim_set_hl(0, "Visual", { bg = "#4a4a5e", bold = true })

        -- 1. Force global floating windows and borders to be transparent
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })

        -- 2. Force Snacks-specific windows to be transparent
        vim.api.nvim_set_hl(0, "SnacksNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerTitle", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = "NONE" })
      end,
    },

    -- 8. VS Code Style Tabs (Bufferline)
    {
      "akinsho/bufferline.nvim",
      version = "*",
      lazy = false,
      dependencies = "nvim-tree/nvim-web-devicons",
      opts = {
        options = {
          mode = "buffers",
          hover = {
            enabled = true,
            delay = 10,          -- How many milliseconds before it triggers
            reveal = { 'close' } -- Reveals the 'x' icon on hover
          },
          -- 2. Clean up the icons
          buffer_close_icon = '󰅖',
          modified_icon = '●',
          close_icon = '',
          left_trunc_marker = '',
          right_trunc_marker = '',
          always_show_bufferline = true,
          show_close_icon = false, -- Hides the weird global close button in the top right

          -- 3. Diagnostics Integration: Shows LSP errors directly on the tab
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local icon = level:match("error") and " " or " "
            return " " .. icon .. count
          end,

          -- 4. Explorer Offset: Keeps the file tree area totally clean
          offsets = {
            {
              filetype = "snacks_explorer",
              text = "Explorer",
              text_align = "center",
              separator = true
            }
          },
        },

        -- 5. Perfect Oh-Lucy-Evening Sync
        highlights = {
          fill = { bg = "NONE" },
          background = { bg = "NONE" },

          -- Matches your Kitty active tab pink/silver exactly!
          buffer_selected = { fg = "#E85A84", bg = "NONE", bold = true, italic = false },
          buffer_visible = { fg = "#CFD0D7", bg = "NONE", bold = true },
          -- Blends the slant separators smoothly
          separator = { fg = "#342D3B", bg = "NONE" }, -- Inactive Kitty tab bg
          separator_selected = { fg = "#E85A84", bg = "NONE" },
          indicator_selected = { fg = "#E85A84", bg = "#E85A84" },

          -- Inactive Tab Diagnostics
          diagnostic = { bg = "NONE" },
          warning = { bg = "NONE" },
          warning_diagnostic = { bg = "NONE" },
          error = { bg = "NONE" },
          error_diagnostic = { bg = "NONE" },
          modified = { bg = "NONE" },

          -- Active Tab Diagnostics (so it doesn't happen when you click the tab!)
          diagnostic_selected = { bg = "NONE" },
          warning_selected = { bg = "NONE" },
          warning_diagnostic_selected = { bg = "NONE" },
          error_selected = { bg = "NONE" },
          error_diagnostic_selected = { bg = "NONE" },
          modified_selected = { bg = "NONE" },
        }
      },
      keys = {
        { "<A-1>", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Go to Buffer 1" },
        { "<A-2>", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Go to Buffer 2" },
        { "<A-3>", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Go to Buffer 3" },
        { "<A-4>", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Go to Buffer 4" },
        { "<A-5>", "<cmd>BufferLineGoToBuffer 5<cr>", desc = "Go to Buffer 5" },
        { "<A-6>", "<cmd>BufferLineGoToBuffer 6<cr>", desc = "Go to Buffer 6" },
        { "<A-7>", "<cmd>BufferLineGoToBuffer 7<cr>", desc = "Go to Buffer 7" },
        { "<A-8>", "<cmd>BufferLineGoToBuffer 8<cr>", desc = "Go to Buffer 8" },
        { "<A-9>", "<cmd>BufferLineGoToBuffer 9<cr>", desc = "Go to Buffer 9" },
        { "<A-[>", "<cmd>BufferLineCyclePrev<cr>",    desc = "Previous Buffer" },
        { "<A-]>", "<cmd>BufferLineCycleNext<cr>",    desc = "Next Buffer" },
        {
          "<S-x>",
          function()
            vim.cmd("bdelete")
            for _, picker in ipairs(require("snacks").picker.get()) do
              if picker.opts.source == "explorer" then
                picker:close()
              end
            end
          end,
          desc = "Close Current Buffer & Explorer"
        },
      },
    },
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        options = {
          theme = "auto", -- "auto" will try to pull colors from oh-lucy. If it warns, swap to "ayu_dark"
          component_separators = { left = '|', right = '|' },
          section_separators = { left = '', right = '' },
        },
      },
    },
    {
      "lewis6991/gitsigns.nvim",
      opts = {
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      },
    },
    {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {},
      keys = {
        { "<leader>t", "<cmd>TodoQuickFix<cr>", desc = "TODO Quickfix List" },
      },
    },
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      ---@module "ibl"
      ---@type ibl.config
      opts = {},
      config = function()
        require("ibl").setup()
      end,
    },
    {
      "folke/flash.nvim",
      event = "VeryLazy",
      ---@type Flash.Config
      opts = {},
      keys = {
        { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
        { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
        { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
        { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
      },
    },
    {
      "fladson/vim-kitty",
      lazy = false, -- Forces filetype detection to load immediately
    },
    {
      "rmagatti/auto-session",
      lazy = false,

      ---enables autocomplete for opts
      ---@module "auto-session"
      ---@type AutoSession.Config
      opts = {
        suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        -- log_level = 'debug',
      },
    },
    {
      "hasansujon786/super-kanban.nvim",
      dependencies = {
        "folke/snacks.nvim",    -- [required]
        "nvim-orgmode/orgmode", -- [optional] Org format support
      },
      opts = {},                -- optional: pass your config table here
    },
    {
      "Aasim-A/scrollEOF.nvim",
      event = { "CursorMoved", "WinScrolled" },
      opts = {
        insert_mode = true,
        disabled_filetypes = {
          -- It's highly recommended to disable this for terminals,
          -- especially since your config utilizes `snacks.nvim`
          "snacks_terminal",
          "terminal",
        },
      },
    }
  },
  install = { colorscheme = { "oh-lucy-evening" } },
  checker = { enabled = false },
})

-- optionally enable 24-bit colour
vim.opt.termguicolors = true
