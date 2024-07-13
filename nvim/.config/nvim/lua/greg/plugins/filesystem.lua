return {
  -- Buffer-based filesystem editor
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
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
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
  },

  -- Primagen's finder
  { "theprimeagen/harpoon", lazy = true },
}
