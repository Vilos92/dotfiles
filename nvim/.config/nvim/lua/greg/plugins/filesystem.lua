return {
  -- Buffer-based filesystem editor
  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    version = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- Primagen's finder
  "theprimeagen/harpoon",
}
