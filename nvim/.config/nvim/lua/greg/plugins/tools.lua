return {
  -- Undo tree
  { "mbbill/undotree", lazy = true, },

  -- Comments
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
    lazy = true,
  },

  -- vim-fugitive for additional Git capabilities
  { "tpope/vim-fugitive", lazy = true, },

  -- GitHub copilot
  { "github/copilot.vim", lazy = true, }
}
