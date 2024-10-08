if vim.g.vscode then
  return
end

-- Open Oil.
vim.keymap.set("n", "<C-o>", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Open Oil in a new tab.
vim.keymap.set("n", "<C-t>", function()
  vim.cmd("tabe %:p | Oil")
end)

-- Leader based shortcut for opening Oil in a split.
vim.keymap.set("n", "<leader>pe", function()
  vim.cmd("rightbelow vsplit | Oil")
end, { desc = "Open parent directory" })
