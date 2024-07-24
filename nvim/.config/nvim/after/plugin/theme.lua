require("rose-pine")
require("catppuccin")
require("tokyonight")

local themes = {
  {
    name = "rose-pine-moon",
    colorscheme = "rose-pine-moon",
    after = [[
      os.execute('alacritty-theme rose-pine-moon')
    ]],
  },
  {
    name = "rose-pine-dawn",
    colorscheme = "rose-pine-dawn",
    after = [[
      os.execute('alacritty-theme rose-pine-dawn')
    ]],
  },
  {
    name = "catppuccin-latte",
    colorscheme = "catppuccin-latte",
    after = [[
      os.execute('alacritty-theme catppuccin-latte')
    ]],
  },
  {
    name = "catppuccin-frappe",
    colorscheme = "catppuccin-frappe",
    after = [[
      os.execute('alacritty-theme catppuccin-frappe')
    ]],
  },
  {
    name = "catppuccin-macchiato",
    colorscheme = "catppuccin-macchiato",
    after = [[
      os.execute('alacritty-theme catppuccin-macchiato')
    ]],
  },
  {
    name = "catppuccin-mocha",
    colorscheme = "catppuccin-mocha",
    after = [[
      os.execute('alacritty-theme catppuccin-mocha')
    ]],
  },
  {
    name = "tokyonight-night",
    colorscheme = "tokyonight-night",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-night") end)
      os.execute('alacritty-theme tokyonight_night')
    ]],
  },
  {
    name = "tokyonight-storm",
    colorscheme = "tokyonight-storm",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-storm") end)
      os.execute('alacritty-theme tokyonight_storm')
    ]],
  },
  {
    name = "tokyonight-day",
    colorscheme = "tokyonight-day",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-day") end)
      os.execute('alacritty-theme tokyonight_day')
    ]],
  },
  {
    name = "tokyonight-moon",
    colorscheme = "tokyonight-moon",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-moon") end)
      os.execute('alacritty-theme tokyonight_moon')
    ]],
  },
}

require("themery").setup({
  themes = themes, -- Your list of installed colorschemes
  themeConfigFile = "~/.config/nvim/lua/greg/theme.lua",
  livePreview = true, -- Apply theme while browsing. Default to true.
})

vim.keymap.set("n", "<leader>kt", function()
  vim.cmd("Themery")
end)
