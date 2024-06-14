local commentApi = require("Comment.api")

local esc = vim.api.nvim_replace_termcodes(
  "<ESC>", true, false, true
)

-- Toggle current line
vim.keymap.set("n", "<C-/>", function() commentApi.toggle.linewise.current() end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>/", function() commentApi.toggle.linewise.current() end, { noremap = true, silent = true })

-- Toggle selection (linewise)
vim.keymap.set("x", "<C-/>", function()
  vim.api.nvim_feedkeys(esc, "nx", false)
  commentApi.toggle.linewise(vim.fn.visualmode())
end)
vim.keymap.set("x", "<leader>/", function()
  commentApi.toggle.linewise(vim.fn.visualmode())
end)

-- Toggle selection (blockwise)
vim.keymap.set("x", "<C-'>", function()
  vim.api.nvim_feedkeys(esc, "nx", false)
  commentApi.toggle.blockwise(vim.fn.visualmode())
end)
vim.keymap.set("x", "<leader>'", function()
  commentApi.toggle.blockwise(vim.fn.visualmode())
end)
