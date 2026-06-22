if vim.g.vscode then
  return
end

-- Oxlint via native LSP. oxfmt LSP stays enabled for non-TS assets; Vite+ TS/JS
-- formatting uses conform's vp_fmt formatter (see after/plugin/conform.lua).

vim.lsp.config("oxlint", {
  init_options = {
    settings = {
      run = "onType",
      fixKind = "safe_fix",
    },
  },
})

vim.lsp.enable("oxlint")
vim.lsp.enable("oxfmt")

vim.keymap.set("n", "<leader>xl", "<cmd>LspOxlintFixAll<CR>", { desc = "Oxlint fix all" })
