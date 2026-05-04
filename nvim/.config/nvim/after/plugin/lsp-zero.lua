if vim.g.vscode then
  return
end

local lsp = require("lsp-zero")

lsp.preset("recommended")

-- NOTE: `ts_ls` and `rust_analyzer` are auto-configured by `lsp-zero` with `mason-lspconfig`.
-- We only need to configure `lua_ls` with custom settings after `lsp.setup()`.

local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
  ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
  ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
  ["<C-y>"] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
})

cmp_mappings["<Tab>"] = nil
cmp_mappings["<S-Tab>"] = nil

lsp.default_keymaps(cmp_mappings)

lsp.set_preferences({
  suggest_lsp_servers = false,
  sign_icons = {
    error = "E",
    warn = "W",
    hint = "H",
    info = "I",
  },
})

lsp.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set("n", "gd", function()
    vim.lsp.buf.definition()
  end, vim.tbl_extend("force", opts, { desc = "LSP definition" }))
  vim.keymap.set("n", "gs", "<cmd>tab split | lua vim.lsp.buf.definition()<CR>", { desc = "LSP definition (new tab)" })

  vim.keymap.set("n", "K", function()
    vim.lsp.buf.hover()
  end, vim.tbl_extend("force", opts, { desc = "LSP hover" }))
  vim.keymap.set("n", "<leader>vws", function()
    vim.lsp.buf.workspace_symbol()
  end, vim.tbl_extend("force", opts, { desc = "Workspace symbol" }))
  vim.keymap.set("n", "<leader>vd", function()
    vim.diagnostic.open_float()
  end, vim.tbl_extend("force", opts, { desc = "Diagnostic float" }))
  vim.keymap.set("n", "[d", function()
    vim.diagnostic.goto_next()
  end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
  vim.keymap.set("n", "]d", function()
    vim.diagnostic.goto_prev()
  end, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
  vim.keymap.set("n", "<leader>vca", function()
    vim.lsp.buf.code_action()
  end, vim.tbl_extend("force", opts, { desc = "Code action" }))
  vim.keymap.set("n", "<leader>vrr", function()
    vim.lsp.buf.references()
  end, vim.tbl_extend("force", opts, { desc = "References" }))
  vim.keymap.set("n", "<leader>vrn", function()
    vim.lsp.buf.rename()
  end, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
  vim.keymap.set("i", "<C-h>", function()
    vim.lsp.buf.signature_help()
  end, vim.tbl_extend("force", opts, { desc = "Signature help" }))
end)

lsp.setup()

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim", "MiniStarter" },
      },
    },
  },
})
vim.lsp.enable("lua_ls")

vim.diagnostic.config({
  virtual_text = true,
})
