if vim.g.vscode then
  return
end

vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
