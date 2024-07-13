require("rose-pine")
require("catppuccin")
require("tokyonight")

local themes = {
  "rose-pine-moon",
  "rose-pine-dawn",
  "catppuccin-latte",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha",
  {
    name = "tokyonight-night",
    colorscheme = "tokyonight-night",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-night") end)
    ]]
  },
 {
    name = "tokyonight-storm",
    colorscheme = "tokyonight-storm",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-storm") end)
    ]]
  },
  {
    name = "tokyonight-day",
    colorscheme = "tokyonight-day",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-day") end)
    ]]
  },
  {
    name = "tokyonight-moon",
    colorscheme = "tokyonight-moon",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-moon") end)
    ]]
  },
}

require("themery").setup({
  themes = themes, -- Your list of installed colorschemes
  themeConfigFile = "~/.config/nvim/lua/greg/theme.lua",
  livePreview = true, -- Apply theme while browsing. Default to true.
})

vim.keymap.set("n", "<leader>kt", function() vim.cmd("Themery") end)
