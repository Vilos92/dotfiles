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
    -- Explorer
    {
      name = "Find Files",
      action = ":lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})",
      section = "Explorer",
    },
    { name = "Recent Files", action = ":Telescope oldfiles", section = "Explorer" },
    {
      name = "Search",
      action = "lua require'telescope.builtin'.grep_string({ search = vim.fn.input(\"Grep > \") })",
      section = "Explorer",
    },
    -- Oil
    { name = "Oil", action = ":Oil", section = "Explorer" },
    -- Configuration
    { name = "Theme", action = ":Themery", section = "Config" },
    { name = "Lazy", action = ":Lazy", section = "Config" },
    { name = "Check Health", action = ":checkhealth", section = "Config" },
    -- Neovim
    { name = "New Buffer", action = "enew", section = "Neovim" },
    { name = "Quit Neovim", action = "qall", section = "Neovim" },
  },

  header = header,
  footer = footer,
})
