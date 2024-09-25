if vim.g.vscode then
  return
end

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.completion.spell,
    -- requires none-ls-extras.nvim
    require("none-ls.diagnostics.eslint_d"),
    -- requires none-ls-shellcheck.nvim
    require("none-ls-shellcheck.diagnostics"),
    require("none-ls-shellcheck.code_actions"),
  },
})

-- Display code actions.
vim.keymap.set("n", "<C-m>", vim.lsp.buf.code_action)
