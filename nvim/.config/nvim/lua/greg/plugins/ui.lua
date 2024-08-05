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
    "Vilos92/media-controls.nvim",
    lazy = true,
    -- Uncomment for local development
    -- dir = "~/greg_projects/media-controls.nvim",
  },
}
