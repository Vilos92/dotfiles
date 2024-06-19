require("rose-pine")
require("catppuccin")

local themes = {
  "rose-pine-moon",
  "rose-pine-dawn",
  "catppuccin-latte",
  "catppuccin-frappe",
  "catppuccin-macchiato",
  "catppuccin-mocha"
}

require("themery").setup({
  themes = themes, -- Your list of installed colorschemes
  themeConfigFile = "~/.config/nvim/lua/greg/theme.lua",
  livePreview = true, -- Apply theme while browsing. Default to true.
})

vim.keymap.set("n", "<leader>kt", function() vim.cmd("Themery") end)
