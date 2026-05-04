vim.g.mapleader = " "

-- Close current tab.
vim.keymap.set("n", "<leader>pq", "<cmd>tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<C-w>", "<cmd>tabclose<CR>", { desc = "Close tab" })

-- Move current tab left or right, using alt left and right.
vim.keymap.set("n", "<leader>{", "<cmd>tabmove -1<CR>", { desc = "Tab move left" })
vim.keymap.set("n", "<leader>}", "<cmd>tabmove +1<CR>", { desc = "Tab move right" })

-- Vertical and horizontal split.
vim.keymap.set("n", "<leader>\\", "<cmd>vsp<CR><C-w>l", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>_", "<cmd>sp<CR><C-w>j", { desc = "Horizontal split" })

-- Navigate panes using vim keys.
vim.keymap.set("n", "<leader>h", "<C-w>h", { desc = "Focus window left" })
vim.keymap.set("n", "<leader>j", "<C-w>j", { desc = "Focus window down" })
vim.keymap.set("n", "<leader>k", "<C-w>k", { desc = "Focus window up" })
vim.keymap.set("n", "<leader>l", "<C-w>l", { desc = "Focus window right" })

-- Resize vim panes.
vim.keymap.set("n", "<leader>[", "5<C-w><", { desc = "Narrower split" })
vim.keymap.set("n", "<leader>]", "5<C-w>>", { desc = "Wider split" })
vim.keymap.set("n", "<leader>-", "5<C-w>-", { desc = "Shorter split" })
vim.keymap.set("n", "<leader>=", "5<C-w>+", { desc = "Taller split" })

-- Quick navigation.
vim.keymap.set("n", "<leader>qj", "<cmd>cnext<CR>zz", { desc = "Forward qfixlist" })
vim.keymap.set("n", "<leader>qk", "<cmd>cprev<CR>zz", { desc = "Backward qfixlist" })

-- Move lines up and down while respecting scope.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- When deleting newline at end of line, keep cursor at beginning.
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in place when navigating page up and down.
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")

-- Keep cursor in middle when doing a local search.
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Paste without replacing buffer with the overwritten content.
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering register" })

-- Allow yanking content to the outer clipboard.
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Allow replacing the currently highlighted term.
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word (buffer)" })

-- Make executable.
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "chmod +x current file" })

-- Rename all occurrences from quick fix navigation.
vim.keymap.set("n", "<leader>r", [[:cfdo %s/\<<C-r><C-w>\>/<C-r><C-w>/g<Left><Left><Left>]], { desc = "Substitute word (quickfix list)" })

-- Write current buffer (`:so` would source buffer text; breaks on mini.starter welcome).
vim.keymap.set("n", "<leader><leader>", function()
  if vim.bo.buftype ~= "" then
    return
  end
  vim.cmd.write()
end, { desc = "Write buffer" })
