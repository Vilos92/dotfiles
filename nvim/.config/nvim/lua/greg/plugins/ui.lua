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
    "vilos92/media-controls.nvim",
    -- Uncomment for local development
    -- dir = "~/greg_projects/media-controls.nvim",
  },
}
