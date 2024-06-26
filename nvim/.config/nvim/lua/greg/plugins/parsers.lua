return {
  -- Tree sitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      local configs = require("nvim-treesitter.configs")

      configs.setup({
          ensure_installed = {"lua", "vim", "vimdoc", "javascript", "typescript", "html" },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },
        })
    end
 },
  "nvim-treesitter/playground",

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
      "L3MON4D3/LuaSnip"
    }
  },

  -- lsp for formatting (needed for eslint and prettier)
  "neovim/nvim-lspconfig",
  "jose-elias-alvarez/null-ls.nvim",

  -- eslint
  "MunifTanjim/eslint.nvim",

  -- prettier
  "MunifTanjim/prettier.nvim",
}
