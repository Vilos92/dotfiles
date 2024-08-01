if vim.g.vscode then
  return
end

require("lualine").setup({
  options = { theme = "auto" },
})
