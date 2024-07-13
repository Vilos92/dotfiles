local header = [[
        ___ ____  
__   __/ _ \___ \ 
\ \ / / (_) |__) |
 \ V / \__, / __/ 
  \_/    /_/_____|
]]

local footer = "Hey Greg, the current date is " .. os.date("%B %d, %Y")

require("mini.starter").setup({
  items = {
    -- Telescope
    {
      name = "Find Files",
      action = ":lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})",
      section = "Telescope",
    },
    { name = "Recent Files", action = ":Telescope oldfiles", section = "Telescope" },
    {
      name = "Search",
      action = "lua require'telescope.builtin'.grep_string({ search = vim.fn.input(\"Grep > \") })",
      section = "Telescope",
    },
    -- Oil
    { name = "Oil", action = ":Oil", section = "Oil" },
    -- Lazy
    { name = "Lazy", action = ":Lazy", section = "Lazy" },
    -- Theme
    { name = "Theme", action = ":Themery", section = "Theme" },
    -- Nvim
    { name = "New buffer", action = "enew", section = "Nvim" },
    { name = "Quit Neovim", action = "qall", section = "Nvim" },
  },

  header = header,
  footer = footer,
})
