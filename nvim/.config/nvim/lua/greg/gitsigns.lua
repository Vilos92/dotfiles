local M = {}

local setup_done = false

function M.setup()
  if setup_done or vim.g.vscode then
    return setup_done
  end

  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok then
    return false
  end

  gitsigns.setup({
    word_diff = true,
    numhl = true,
    signs = {
      add = { text = "+" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "?" },
    },
    on_attach = function(bufnr)
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
      end

      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "Git: next hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "Git: previous hunk")

      map("n", "<leader>gi", gitsigns.preview_hunk_inline, "Git: preview hunk inline")
    end,
  })

  vim.keymap.set("n", "<leader>gt", function()
    require("greg.git").open_changed_tabs()
  end, { desc = "Git: open changed files in tabs" })
  vim.keymap.set("n", "<leader>gw", gitsigns.toggle_word_diff, { desc = "Git: toggle inline word diff" })

  setup_done = true
  return true
end

return M
