return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = true,
  },

  -- Splash screen
  { "echasnovski/mini.starter", version = false, lazy = true },

  -- Undo tree
  { "mbbill/undotree" },

  -- Comments
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
    lazy = true,
  },

  -- vim-fugitive for additional Git capabilities
  { "tpope/vim-fugitive" },

  -- GitHub copilot
  { "github/copilot.vim" },

  {
    "media-controls.nvim",
    dir = "~/greg_projects/media-controls.nvim",
    opts = { name = "greg" },
  },
}
