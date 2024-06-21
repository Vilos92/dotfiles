-- Leader based shortcut for opening Oil.
vim.keymap.set("n", "<leader>pe", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- Alternative that mimics the VSCode "open explorer" shortcut.
vim.keymap.set("n", "<C-b>", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Open Oil in a new tab.
vim.keymap.set("n", "<C-t>", function()
  vim.cmd("tabnew | Oil")
end)

-- Open Oil in a vertical split.
vim.keymap.set("n", "<C-o>", function()
  vim.cmd("rightbelow vsplit | Oil")
end)
