return {
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
  { "github/copilot.vim" }
}
