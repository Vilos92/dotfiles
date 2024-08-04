return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = true,
  },

  -- Splash screen
  { "echasnovski/mini.starter", version = false, lazy = true },

  -- MacOS media status and controls
  {
    "media-controls.nvim",
    dir = "~/greg_projects/media-controls.nvim",
    opts = {},
  },
}
