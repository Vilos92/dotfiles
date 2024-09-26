if vim.g.vscode then
  return
end

require("rose-pine")
require("catppuccin")
require("tokyonight")

local themes = {
  {
    name = "rose-pine-moon",
    colorscheme = "rose-pine-moon",
    after = [[
      os.execute('alacritty-theme rose-pine-moon > /dev/null 2>&1')
    ]],
  },
  {
    name = "rose-pine-dawn",
    colorscheme = "rose-pine-dawn",
    after = [[
      os.execute('alacritty-theme rose-pine-dawn > /dev/null 2>&1')
    ]],
  },
  {
    name = "catppuccin-latte",
    colorscheme = "catppuccin-latte",
    after = [[
      os.execute('alacritty-theme catppuccin-latte > /dev/null 2>&1')
    ]],
  },
  {
    name = "catppuccin-frappe",
    colorscheme = "catppuccin-frappe",
    after = [[
      os.execute('alacritty-theme catppuccin-frappe > /dev/null 2>&1')
    ]],
  },
  {
    name = "catppuccin-macchiato",
    colorscheme = "catppuccin-macchiato",
    after = [[
      os.execute('alacritty-theme catppuccin-macchiato > /dev/null 2>&1')
    ]],
  },
  {
    name = "catppuccin-mocha",
    colorscheme = "catppuccin-mocha",
    after = [[
      os.execute('alacritty-theme catppuccin-mocha > /dev/null 2>&1')
    ]],
  },
  {
    name = "nord",
    colorscheme = "nord",
    after = [[
      os.execute('alacritty-theme nord > /dev/null 2>&1')
    ]],
  },
  {
    name = "tokyonight-night",
    colorscheme = "tokyonight-night",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-night") end)
      os.execute('alacritty-theme tokyonight_night > /dev/null 2>&1')
    ]],
  },
  {
    name = "tokyonight-storm",
    colorscheme = "tokyonight-storm",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-storm") end)
      os.execute('alacritty-theme tokyonight_storm > /dev/null 2>&1')
    ]],
  },
  {
    name = "tokyonight-day",
    colorscheme = "tokyonight-day",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-day") end)
      os.execute('alacritty-theme tokyonight_day > /dev/null 2>&1')
    ]],
  },
  {
    name = "tokyonight-moon",
    colorscheme = "tokyonight-moon",
    after = [[
      vim.schedule(function() vim.cmd("colorscheme tokyonight-moon") end)
      os.execute('alacritty-theme tokyonight_moon > /dev/null 2>&1')
    ]],
  },
}

require("themery").setup({
  themes = themes,
  livePreview = true,
})

vim.keymap.set("n", "<leader>t", function()
  vim.cmd("Themery")
end)
