if vim.g.vscode then
  return
end

local null_ls = require("null-ls")

local eslint_config_files = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.json",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
}

local sources = {
  null_ls.builtins.formatting.stylua,
  null_ls.builtins.completion.spell,
  -- requires none-ls-shellcheck.nvim
  require("none-ls-shellcheck.diagnostics"),
  require("none-ls-shellcheck.code_actions"),
}

-- Only run eslint_d when an ESLint config exists at the project root.
-- Avoids JSON-decode errors in Vite+ / oxlint-only repos that have no ESLint config.
table.insert(
  sources,
  require("none-ls.diagnostics.eslint_d").with({
    condition = function(utils)
      return utils.root_has_file(eslint_config_files)
    end,
  })
)

null_ls.setup({ sources = sources })

-- Display code actions.
vim.keymap.set("n", "<C-m>", vim.lsp.buf.code_action, { desc = "Code action" })
