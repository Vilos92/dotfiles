if vim.g.vscode then
  return
end

local header = [[
        ___ ____  
__   __/ _ \___ \ 
\ \ / / (_) |__) |
 \ V / \__, / __/ 
  \_/    /_/_____|
]]

local footer = (function()
  return function()
    return "Hey Greg,\n\n📅 The current date is " .. os.date("%B %d, %Y")
  end
end)()

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
      action = "lua require'telescope.builtin'.grep_string({ search = vim.fn.input('Grep > '), vimgrep_arguments = { 'rg', '--hidden', '--glob', '!.git/**', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case' } })",
      section = "Explorer",
    },
    -- Oil
    { name = "Oil", action = ":Oil", section = "Explorer" },
    -- Configuration
    { name = "Theme", action = ":Themery", section = "Config" },
    { name = "Lazy", action = ":Lazy", section = "Config" },
    { name = "Check Health", action = ":checkhealth", section = "Config" },
    -- Neovim
    { name = "Create Buffer", action = "enew", section = "Neovim" },
    { name = "Quit Neovim", action = "qall", section = "Neovim" },
  },

  header = header,
  footer = footer,
})
