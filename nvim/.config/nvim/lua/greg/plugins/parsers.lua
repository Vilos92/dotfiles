return {
  -- Tree sitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "bash",
          "gleam",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "rust",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
    dependencies = {
      "OXY2DEV/markview.nvim",
    },
    lazy = false,
    -- Ensure this loads before `markview.nvim`.
    priority = 50,
  },

  -- Tree sitter playground
  { "nvim-treesitter/playground" },

  -- Markdown editing
  {
    "OXY2DEV/markview.nvim",
    lazy = false, -- Recommended
    -- Ensure this loads after `nvim-treesitter`.
    priority = 49,
    -- ft = "markdown" -- If you decide to lazy-load anyway

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- lsp-zero
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
    },
  },

  -- Quickstart nvm lsp configs
  {
    "neovim/nvim-lspconfig",
    lazy = true,
  },

  -- Linter + code actions
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
      "gbprod/none-ls-shellcheck.nvim",
    },
    lazy = true,
  },

  -- Formatter (needed for prettier)
  {
    "stevearc/conform.nvim",
    opts = {},
    lazy = true,
  },
}
