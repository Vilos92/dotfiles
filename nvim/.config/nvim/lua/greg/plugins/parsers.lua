return {
  -- Tree sitter
  {
    "nvim-treesitter/nvim-treesitter",
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
    lazy = true,
  },
  { "nvim-treesitter/playground" },

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

  -- lsp for formatting (needed for eslint and prettier)
  { "neovim/nvim-lspconfig", lazy = true },
  { "jose-elias-alvarez/null-ls.nvim", lazy = true },

  -- eslint
  { "MunifTanjim/eslint.nvim", lazy = true },

  -- prettier
  { "MunifTanjim/prettier.nvim", lazy = true },
}
