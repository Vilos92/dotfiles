if vim.g.vscode then
  return
end

local lsp = require("lsp-zero")
local cmp = require("cmp")

lsp.set_sign_icons({
  error = "E",
  warn = "W",
  hint = "H",
  info = "I",
})

lsp.on_attach(function(_client, bufnr)
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

lsp.extend_lspconfig({
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

require("mason").setup({})
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "rust_analyzer", "ts_ls" },
  handlers = {
    -- lua_ls is enabled via native vim.lsp below; mason only installs the binary.
    lua_ls = function() end,
    function(server_name)
      require("lspconfig")[server_name].setup({})
    end,
  },
})

local cmp_select = { behavior = cmp.SelectBehavior.Select }
cmp.setup({
  sources = {
    { name = "nvim_lsp" },
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
    ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
  }),
})

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
