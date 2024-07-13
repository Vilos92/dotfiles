return {
  -- Theme manager
  { "zaldih/themery.nvim", lazy = true, },

  -- Themes
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = false,
    priority = 1000,
    opts = {},
  },
}