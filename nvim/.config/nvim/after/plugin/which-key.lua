if vim.g.vscode then
  return
end

local wk = require("which-key")

wk.setup({
  preset = "modern",
})

wk.add({
  { "<leader>p", group = "pick (Telescope · Oil)" },
  { "<leader>v", group = "LSP" },
  { "<leader>g", group = "git" },
  { "<leader>q", group = "quickfix" },
})

vim.keymap.set("n", "<leader>?", function()
  wk.show({ global = false })
end, { desc = "Which-key (this buffer)" })
